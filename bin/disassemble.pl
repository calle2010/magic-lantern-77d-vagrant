#!/usr/bin/perl

# disassemble alien binary blobs
# look for "ldr .., [pc + #nn]" etc. 
# and add strings and values it refers to
#
# (c) 2008 chr
# GPL V3+
#
# v0.2.1:
# * create labels for branch targets
# v0.2:
# * catch unaligned strings
# * note on strings
# * check for integer overflow

# use Data::Dumper;
# $Data::Dumper::Sortkeys = 1;

# Added to support execution of disassembler.pl
# when not in the same folder as binary file to
# be disassembled.
use Cwd;
$firmware_basepath = getcwd;

# adjust these for your needs (note final slash):
#$path = "$ENV{'HOME'}/gcc-4.1-arm/bin/";
$path = "";

# note on "strings": default is a minimum length of 4 chars.
# So if u are hunting for e.g. "FI2" add -n3
# However, it gives a lot of false positive.
$strdump = "strings -t x";
$objdump = "${path}arm-elf-objdump";
$objcopy = "${path}arm-elf-objcopy";

if (@ARGV != 2) {
	die("Usage: $0 0x<offset> <dump.bin>");
}

$offset  = $ARGV[0];
$binfile = $ARGV[1];
$firmware_file_path = "$firmware_basepath/$ARGV[1]";

# check if we wrap over
die "error stat($firmware_file_path): $!" unless ($flen = (stat($firmware_file_path))[7]);

if ( hex($offset) + $flen - 1 > 0xffffffff) {
	die "offset + filesize - 1 > 0xffffffff. We can't wrap around!\n\ngame over"
}

#####
print "string dump\n";
my %strings;
open(IN, "$strdump \"$firmware_file_path\" |") or die "cannot start $strdump \"$firmware_file_path\": $!";
open(OUT,">$firmware_file_path.strings") or die "cannot write to $firmware_file_path.strings: $!";
while (<IN>) {
	/^ *([[:xdigit:]]*) (.*)/;
	my $addr     = hex($1) + hex($offset);
	my $addr_str = sprintf("%08x", $addr);
	$strings{$addr_str} = $2;

	print OUT "$addr_str $2\n"; 

	# align string address so unaligned strings appears in disassemble
	$addr_str = sprintf("%08x", $addr & ~0x3);
	my $offs = $addr & 0x3;
	$strings{$addr_str} = '.' x $offs . $2;
	
}
close IN;
close OUT;

#$strings{'ff810164'} = "TEST test";
#$strings{'ff810420'} = "add test";
#print Dumper(\%strings);
#exit;

#####
print "create elf file\n";

`$objcopy --change-addresses=$offset -I binary -O elf32-littlearm -B arm \"$firmware_file_path\" \"$firmware_file_path.elf\"`;
`$objcopy --set-section-flags .data=code,load,alloc,content \"$firmware_file_path.elf\"`;

#####
print "label scan\n";
my %labels;
open(IN, "$objdump -d \"$firmware_file_path.elf\" |")
      or die "cannot start $objdump \"$firmware_file_path\": $!";
open(OUT,">$firmware_file_path.labels") or die "cannot write to $firmware_file_path.labels: $!";

while (<IN>) {
        if (my ($addr, $dest) = $_ =~ /^ *([[:xdigit:]]+):[ \t]+[[:xdigit:]]+[ \t]+[Bb][[:alpha:]]*[ \t]+([[:xdigit:]]+)/) {
                if ($labels{$dest} lt 1) {
                        print OUT "$dest ($addr)\n";
                }
                $labels{$dest} += 1;
                print "\r0x$addr  ";
        }
}
close IN;
close OUT;

#####
print "\ndisassemble and string lookup\n";

open(IN, "$objdump -d \"$firmware_file_path.elf\" |")
      or die "cannot start $objdump \"$firmware_file_path\": $!";
open(OUT,">$firmware_file_path.dis") or die "cannot write to $firmware_file_path.dis: $!";
open(BIN, "<$firmware_file_path") or die "cannot read $firmware_file_path";

binmode BIN;

while (<IN>) {
	if ($_ eq "	...\n") { print OUT $_; next;}

	my ($addr, $line) = $_ =~ /^ *([[:xdigit:]]*):(.*)/ or next;

	# ff810b98:	e51f2060 	ldr	r2, [pc, #-96]	; ff810b40 <_binary_dump_bin_start+0xb40>
	# ff815dd4:	e28f10dc 	add	r1, pc, #220	; 0xdc
	if (
		($line =~ /^(.*\tldr.*\[pc, #([-\d]+).*; )/) ||
		($line =~ /^(.*\tadd.*pc, #([-\d]+).*; )/)
	) {
		$line = $1;
		my $off = hex($addr) - hex($offset) + $2 + 8;
		my $point = sprintf("%08x", hex($addr) + $2 + 8);
		my $value = &get_word($off);
		$line .= "$point: ($value) ";
		if (my $str = $strings{$point}) {
			# add pointed string
			$line .= qq| *"$str"|;
		}
		elsif (my $str = $strings{$value}) {
			# pointer to pointer ...
			$line .= qq| **"$str"|;
		}
	} 
	# ff815e1c:	e24f0090 	sub	r0, pc, #144	; 0x90
	elsif ($line =~ /^(.*\tsub.*pc, #([-\d]+).*; )/) {
		$line = $1;
		my $off = hex($addr) - hex($offset) - $2 + 8;
		my $point = sprintf("%08x", hex($addr) - $2 + 8);
		my $value = &get_word($off);
		$line .= "$point: ($value) ";
		if (my $str = $strings{$point}) {
			$line .= qq| *"$str"|;
		}
		elsif (my $str = $strings{$value}) {
			$line .= qq| **"$str"|;
		}
	}
        # ff81015c:       3afffffc        bcc     ff810154 <_binary__blah...>
        elsif ($line =~ /^([ \t]*[[:xdigit:]]+[ \t]+[Bb][[:alpha:]]*[ \t]+)([[:xdigit:]]+)/) {
                $line = "$1loc_$2"
        }
        # insert label
        if ($labels{$addr} gt 1) {
                print OUT "loc_$addr: ; $labels{$addr} refs\n";
        } elsif ($labels{$addr} gt 0) {
                print OUT "loc_$addr:\n";
        }
	# add string comment
	if (my $str = $strings{$addr}) {
		print OUT qq|"$str":\n|;
	}
	print OUT "$addr: $line\n"; 
	print "\r0x$addr  ";
}
close IN;
close OUT;

#####
print "\njob complete!\n";

sub get_word {
	my $off = shift;
	my $ret;

	seek(BIN, $off, 0);
	my $c = read(BIN, $ret, 4);# or die "off: $off $! ($ret)";
	return ($c > 0 ? sprintf("%08x", unpack("I", $ret)) : '???');
}
