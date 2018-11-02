#!/usr/bin/perl

# modifiearm-none-eabi-objdumpd fork of http://chdk.wikia.com/wiki/GPL:disassemble.pl
# only meant to be used on dumps which are only using Thumb(-2) instructions
# it expects lowercase disassembly listing (which is what objdump should output)
# registers r10, r11, r12 are expected to be named sl, fp, ip
# v0.5  update tbb/tbh jumptable support, add another jumptable variant seen in a DIGIC 8 fw
# v0.4  objcopy no longer needed, use objdump directly (needs recent binutils)
# v0.3  notice references to strings that start with control chars
# v0.2  new option (h): convert decimal immediate values to hex
#       new option (r): try converting adr and ldr instructions to position independent ldr (may not be 100% secure)
# v0.12 special handling of tbb, tbh jumptables, bugfixes
# v0.11 tbb, tbh jumptables: try to find element count
# v0.1 initial version

# original copyright notice and notes below

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
#$path = "";
$path = "$ENV{'HOME'}/bin/arm-none48/bin/";

# note on "strings": default is a minimum length of 4 chars.
# So if u are hunting for e.g. "FI2" add -n3
# However, it gives a lot of false positive.
$strdump = $path."arm-none-eabi-strings -t x";
$objdump = $path."arm-none-eabi-objdump";
$strip = $path."arm-none-eabi-strip";

# transform immediate constants from objdump's decimal format to hexadecimal?
$opt_immhex = 0;
# output more "ready-to-use" disassembly (transform ldr and adr instructions to position-independent ldr)
$opt_rtu = 0;
# skip lines that became marked as non-instructions (jumptables only)
$opt_skipm = 0;

if (@ARGV < 2) {
    die("Utility to disassemble ARMv7/Thumb-2 binaries\n\nUsage: $0 0x<offset> <dump.bin> [options]\nread script for options (h,r,s)\n");
}
else {
    if ($ARGV[2] =~ /.*[hH].*/) {
        $opt_immhex = 1;
    }
    if ($ARGV[2] =~ /.*[rR].*/) {
        $opt_rtu = 1;
    }
    if ($ARGV[2] =~ /.*[sS].*/) {
        $opt_skipm = 1;
    }
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
open(BIN, "<$firmware_file_path") or die "cannot read $firmware_file_path";
binmode BIN;

while (<IN>) {
    /^ *([[:xdigit:]]*) (.*)/;
    my $ofs = hex($1);
    my $addr     = $ofs + hex($offset);
    my $addr_str = sprintf("%x", $addr);
    my $str = $2;
    my $bad;
    my $ok = 1;
    if (($bad) = $2 =~ /.*[\`\"\@\$\\]+.*/) {
        #print OUT "$addr_str $str BAD1\n"; 
        next;
    }
    if (($bad) = $2 =~ /^[a-z][A-Z].*/) {
        #print OUT "$addr_str $str BAD2\n"; 
        next;
    }
    if ( ($ofs&3) ne 0 ) {
        my $pr = get_num($ofs-1,1);
        my $pr2 = get_num($ofs-2,1);
        if ( (($pr eq 0xa) || ($pr eq 0xd) || ($pr eq 9)) ) {
            if ( (($pr2 eq 0xa) || ($pr2 eq 0xd) || ($pr2 eq 9)) ) {
                $strings{$addr-2} = "..".$str;
                print OUT ".. ";
            }
            else {
                $strings{$addr-1} = ".".$str;
                print OUT ". ";
            }
            $ok = 0;
        }
    }
    if ($ok eq 1) {
        $strings{$addr} = $str;
    }
 
    print OUT "$addr_str $str\n"; 
 
    # align string address so unaligned strings appear in disassembly
    # $addr_str = sprintf("%x", $addr & ~0x3);
    # my $offs = $addr & 0x3;
    # $strings{$addr_str} = '.' x $offs . $2;
 
}
close IN;
close OUT;
 
#$strings{'ff810164'} = "TEST test";
#$strings{'ff810420'} = "add test";
#print Dumper(\%strings);
#exit;
 
#####

#####
print "label scan\n";
my %labels;
open(IN, "$objdump -D -marm -b binary --adjust-vma=$offset -Mforce-thumb -d \"$firmware_file_path\" |")
      or die "cannot start $objdump \"$firmware_file_path\": $!";
open(OUT,">$firmware_file_path.labels") or die "cannot write to $firmware_file_path.labels: $!";
 
while (<IN>) {
        if (my ($addr, $dest) = $_ =~ /^ *([[:xdigit:]]+):.+\tb[[:alpha:]\.]*\t0x([[:xdigit:]]+)/) {
                if ($labels{$dest} lt 1) {
                        print OUT "$dest ($addr)\n";
                }
                $labels{$dest} += 1;
                print "\r0x$addr  ";
        }
        elsif (my ($addr, $dest) = $_ =~ /^ *([[:xdigit:]]+):.+\tcbn?z\tr.+0x([[:xdigit:]]+)/) {
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
# fifo for previous lines
@hist = (" "," "," "," "," "," "," "," "," "," "," "," ");
$histlen = 128;
open(IN, "$objdump -D -marm -b binary --adjust-vma=$offset -Mforce-thumb -d \"$firmware_file_path\" |")
      or die "cannot start $objdump \"$firmware_file_path\": $!";
open(OUT,">$firmware_file_path.dis") or die "cannot write to $firmware_file_path.dis: $!";
open(OUTL,">>$firmware_file_path.labels") or die "cannot write to $firmware_file_path.labels: $!";

# comment out lines before this address
$cmmnt = 0;
$cmmntstr;
 
while (<IN>) {
    if ($_ eq " ...\n") { print OUT $_; next;}
    my ($addr, $words, $iline, $scrap, $scrap2, $target) = $_ =~ /^ *([[:xdigit:]]*):\t([[:xdigit:] ]*)\t(.*)(\t; )\((.*)0x([[:xdigit:]]*)\)/;
    if ($addr eq "") {
        ($addr, $words, $iline, $scrap, $scrap2, $target) = $_ =~ /^ *([[:xdigit:]]*):\t([[:xdigit:] ]*)\t(.*)(\t; )(.*)0x([[:xdigit:]]*)/; 
    }
    if ($addr eq "") {
        ($addr, $words, $iline) = $_ =~ /^ *([[:xdigit:]]*):\t([[:xdigit:] ]*)\t(.*)/; 
        my $scrap, $scrap2, $target;
    }
    if ($addr eq "") {
        next;
    }

    my $wdstrim = $words;
    $wdstrim =~ s/ //g ;
    my $rawlen = length($wdstrim)/2;

    # skip "marked" lines if user decided so... except when incorrect long inst interferes
    if ($opt_skipm eq 1) {
        if (hex($addr)+$rawlen-1 < $cmmnt) {
            next;
        }
    }

    my $line = "\t".$words."\t".$iline;

    my $additions = "";

    # 800b698:	4919      	ldr	r1, [pc, #100]	; (0x800b700)
    #    800c:	f8df d054 	ldr.w	sp, [pc, #84]	; 0x8064 
    if (
        ($target ne "") &&
        ($iline =~ /^(ldr(.*?)\t(.+?)\[pc, #([-\d]+).*)/)
    ) {
        $line .= $scrap;
        my $off = hex($target) - hex($offset);
        my $point = $target;
        my $value = &get_word($off);
        if ($opt_rtu eq 1) {
            my $s1 = $2;
            my $svalue = sprintf("%x",hex($value));
            if ($s1 eq ".w") {$s1 = ""}
            $line = "\t".$words."\t"."ldr".$s1."\t".$3."=0x$svalue".$scrap
        }
        else {
            $line .= "0x$point: ($value) ";
        }
        if (my $str = $strings{hex($point)}) {
            # add pointed string
            $line .= qq| *"$str"|;
        }
        elsif (my $str = $strings{hex($value)}) {
            # pointer to pointer ...
            $line .= qq| **"$str"|;
        }
        elsif ( (( hex($point) & 1) == 1) &&
                (( hex($point) & 0xf0000000) == ( hex($addr) & 0xf0000000)) &&
                ( hex($point) < ((hex($addr)+0x2000000) & 0xff000000))
        ) {
            # could be a subroutine address
            $line .= "...sub?";
        }
        elsif ( (( hex($value) & 1) == 1) &&
                (( hex($value) & 0xf0000000) == ( hex($addr) & 0xf0000000)) &&
                ( hex($value) < ((hex($addr)+0x2000000) & 0xff000000))
        ) {
            # could be a subroutine address
            $line .= "...sub?";
        }
    }
    # fc036fd6: 	a1ff      	add	r1, pc, #1020	; (adr r1, 0xfc0373d4)
    # the add -> adr conversion may be incorrect when 'add' is conditional
    elsif (
        ($target ne "") &&
        ($iline =~ /^(add(.*?)\t(.+?)pc, #([-\d]+)).*/)
    ) {
        $line .= $scrap;
        my $off;
        my $point;
        if (hex($target) < hex($offset)) {
            # sometimes $target is not an address but an offset, calculate with the decimal immediate $4 instead)
            $point = ( hex($addr) + 4 ) & 0xfffffffc;
            $point = $point + $4;
            $off = $point - hex($offset);
            $point = sprintf("%x",$point);
        }
        else {
            $off = hex($target) - hex($offset);
            $point = $target;
        }
        my $value = &get_word($off);
        if ($opt_rtu eq 1) {
            my $s1 = $2;
            if ($s1 eq "w") {$s1 = ""}
            if ($s1 eq ".w") {$s1 = ""}
            my $spoint = sprintf("%x",hex($point));
            #$line = "\t".$words."\t"."ldr".$s1."\t".$3."=0x$value".$scrap
            $line = "\t".$words."\t"."ldr".$s1."\t".$3."=0x$spoint".$scrap."(".$iline.")"
        }
        else {
            $line .= "0x$point: ($value)";
        }
        if (my $str = $strings{hex($point)}) {
            # add pointed string
            $line .= qq| *"$str"|;
        }
        elsif (my $str = $strings{hex($value)}) {
            # pointer to pointer ...
            $line .= qq| **"$str"|;
        }
        elsif ( (( hex($point) & 1) == 1) &&
                (( hex($point) & 0xf0000000) == ( hex($addr) & 0xf0000000)) &&
                ( hex($point) < ((hex($addr)+0x2000000) & 0xff000000))
        ) {
            # could be a subroutine address
            $line .= "...sub?";
        }
        elsif ( (( hex($value) & 1) == 1) &&
                (( hex($value) & 0xf0000000) == ( hex($addr) & 0xf0000000)) &&
                ( hex($value) < ((hex($addr)+0x2000000) & 0xff000000))
        ) {
            # could be a subroutine address
            $line .= "...sub?";
        }
    } 
    # fc020922: 	f2af 112c 	subw	r1, pc, #300	; 0x12c
    # the sub -> adr conversion may be incorrect when 'sub' is conditional
    # destination calculation is: ((addr+4)&0xfffffffc)-offset
    elsif ($iline =~ /^(sub(.*?)\t(.+?)pc, #([-\d]+)).*/)
    {
        my $s2 = $4;
        if ($scrap eq "") {
            $scrap = "\t; ";
        }
        $line .= $scrap;
        my $align1 = hex($addr) & 0x2;
        if ($align1 == 0) {
            $align1 = 2;
        }
        else {
            $align1 = 0;
        }
        # align2: bit0 might be the thumb bit, these references are for subroutines(?)
        my $align2 = ($s2+0) & 0x1;
        my $off = hex($addr) - hex($offset) - $s2 + 2 + $align1 - $align2;
        my $point = sprintf("%08x", hex($addr) - $s2 + 2 + $align1 - $align2);
        my $spoint = sprintf("%x",hex($point));
        my $value = &get_word($off);
        if (($align2 == 1) && ($value >= hex($offset))) {
            if ($opt_rtu eq 1) {
                my $s1 = $2;
                if ($s1 eq "w") {$s1 = ""}
                # $line = "\t".$words."\t"."ldr".$s1."\t".$3."=0x$value".$scrap
                $line = "\t".$words."\t"."ldr".$s1."\t".$3."=0x$spoint".$scrap."(".$iline.")"
            }
            else {
                $line .= "sub_$point: ($value) ";
            }
        }
        else {
            if ($opt_rtu eq 1) {
                my $s1 = $2;
                if ($s1 eq "w") {$s1 = ""}
                # $line = "\t".$words."\t"."ldr".$s1."\t".$3."=0x$value".$scrap
                $line = "\t".$words."\t"."ldr".$s1."\t".$3."=0x$spoint".$scrap."(".$iline.")"
            }
            else {
                $line .= "0x$point: ($value) ";
            }
        }
        if (my $str = $strings{hex($point)}) {
            $line .= qq| *"$str"|;
        }
        elsif (my $str = $strings{hex($value)}) {
            $line .= qq| **"$str"|;
        }
    }
    # fc0d08b6: 	f181 ea34 	blx	0xfc251d20
    # fc0d08c8: 	d035      	beq.n	0xfc0d0936
    # fc0d08f0: 	f7ff fdc2 	bl	0xfc0d0478
    # bkpt is special cased
    # fc055f14: 	beec      	bkpt	0x00ec
    elsif ($line =~ /^(.*\t(b[[:alpha:]\.]*)\t)0x([[:xdigit:]]+)/) {
        if ($2 ne "bkpt") {
            $line = "$1loc_$3"
        }
    }
    # fc02015a: 	b14c      	cbz	r4, 0xfc020170
    elsif ($line =~ /^(.*\tcbn?z\tr.+)0x([[:xdigit:]]+)/) {
            $line = "$1loc_$2"
    }
    # fc06fa58: 	e8df f001 	tbb	[pc, r1]
    # fc06e5a2: 	e8df f010 	tbh	[pc, r0, lsl #1]
    # pc based table branch
    elsif ($line =~ /^(.*\ttb([bh])\t\[pc, ([rlsfi][[:digit:]rlp]).*)/) {
            my $guess = &get_regcmp($3);
            my $o = ($2 eq "b") ? 1 : 2;
            if ($o == 2) {
                # rule out insane looking numbers
                if ($guess > 7999) { $guess = 0; }
                $cmmnt = $guess*2;
            }
            else {
                # rule out insane looking numbers
                if ($guess > 159) { $guess = 0; }
                $cmmnt = ($guess + 1) & 0xfffffffe;
            }
            $line = "$1\t; (jumptable: $3, $guess elements)";
            # determine next real instruction address
            $cmmnt += hex($addr) + 4;
            # print a nice jumptable
            my $n1, $m, $p, $pp, $ppp;
            for ($n1 = 0; $n1 < $guess; $n1++) {
                $m = get_mem(hex($addr) - hex($offset) + 4 + $o*$n1, $o);
                $p = hex($addr) + 4 + hex($m) * 2;
                $pp = sprintf("%x", $p);
                $ppp = sprintf("%x", hex($addr)+$n1*$o+4);
                if ($labels{$pp} lt 1) {
                        # add new label to the labels file
                        print OUTL "$pp ($addr)\n";
                }
                # add label to the list so it can be picked up later
                $labels{$pp} += 1;
                # the jumptable text can't be printed right now, let's buffer it
                $additions .= "$ppp: \t; jump to\tloc_$pp (case ".$n1.")\n";
            }
    }
    # table branch with non-pc base
    elsif ($line =~ /^(.*\ttb([bh])\t\[.+, ([rlsfi][[:digit:]rlp]).*)/) {
        my $guess = &get_regcmp($3);
        $line = "$1\t; (jumptable: $3, $guess elements)"
    }
    # possible very large jumptable (seen in D8 disasm)
    elsif ($line =~ /^(.*\tadd\tpc, ([rlsfi][[:digit:]rlp]).*)/) {
        my $lin1 = $1;
        my $rid1 = $2;
        if (($hist[1] =~ /.*\tadd\t([rlsfi][[:digit:]rlp]), pc.*/) && ($1 eq $rid1)){
            my $stri = $hist[2];
            if ($stri =~ /^(.*\tnop.*)/) {
                $stri = $hist[3];
            }
            my $rid2 = "";
            if (($stri =~ /.*\tmov.*\t([rlsfi][[:digit:]rlp]), ([rlsfi][[:digit:]rlp]), lsl #2.*/) && ($1 eq $rid1)) {
                $rid2 = $2;
            }
            elsif (($stri =~ /.*\tlsl.*\t([rlsfi][[:digit:]rlp]), ([rlsfi][[:digit:]rlp]), #2.*/) && ($1 eq $rid1)) {
                $rid2 = $2;
            }
            # todo: try evaluating jumps when searching for the cmp instruction, to avoid false positives
            if ($rid2 ne "") {
                my $guess = &get_regcmp2($rid2);
                $line = "$lin1\t; (jumptable: $rid1, $guess elements)";
                $cmmnt = ($guess + 0) * 4;
                $cmmnt += hex($addr) + 4;

                my $n1, $m, $p, $pp, $ppp;
                for ($n1 = 0; $n1 < $guess; $n1++) {
                    $m = get_mem(hex($addr) - hex($offset) + 4 + 4*$n1, 4);
                    $p = hex($addr) + 4 + hex($m);
                    $pp = sprintf("%x", $p);
                    $ppp = sprintf("%x", hex($addr)+$n1*4+4);
                    if ($labels{$pp} lt 1) {
                            # add new label to the labels file
                            print OUTL "$pp ($addr)\n";
                    }
                    # add label to the list so it can be picked up later
                    $labels{$pp} += 1;
                    # the jumptable text can't be printed right now, let's buffer it
                    $additions .= "$ppp: \t; jump to\tloc_$pp (case ".$n1.")\n";
                }

            }
        }
    }
    # last category, convert decimal immediate values to hex if requested
    elsif (($opt_immhex eq 1) && ($iline =~ /(.+?#)([[:digit:]]+)(.*)/)) {
        if ($2+0 > 9) {
            my $h = sprintf("0x%x", $2+0);
            $line = "\t".$words."\t".$1.$h.$3;
        }
    }
    # insert label
    if ($labels{$addr} gt 1) {
            print OUT "loc_$addr: ; $labels{$addr} refs\n";
    } elsif ($labels{$addr} gt 0) {
            print OUT "loc_$addr:\n";
    }
    # add string comment
    my $c, $cc;
    for ($c=0; $c<$rawlen; $c++) {
        if (my $str = $strings{hex($addr)+$c}) {
            $cc = '.' x $c;
            print OUT "$cc".qq|"$str":\n|;
        }
    }

    # line is not marked as commented (logic behind this could be smarter)
    if (hex($addr) >= $cmmnt) {
        $cmmntstr = "";
    }
    # write current disassembly line into the target file
    print OUT "$addr: $line$cmmntstr\n";
    # print added text lines, if any
    if ($additions ne "") {
        print OUT $additions;
    }
    # if current line is commented, add comment text (which is fixed at the moment)
    if (hex($addr) < $cmmnt) {
        $cmmntstr = " \t; (jumptable offsets)";
    }
    print "\r0x$addr  ";

    # add line to history
    unshift(@hist, $_);
    # remove last element of history (only if array larger than desired history size)
    if ($#hist >= $histlen) {
        pop(@hist);
    }
}
close IN;
close OUT;
close OUTL;
close BIN;
 
#####
print "\njob complete!\n";
 
sub get_word {
    my $off = shift;
    my $ret;
 
    seek(BIN, $off, 0);
    my $c = read(BIN, $ret, 4);# or die "off: $off $! ($ret)";
    return ($c > 0 ? sprintf("%08x", unpack("I", $ret)) : '???');
}

sub get_mem {
    my $off = shift;
    my $len = shift;
    my $ret;
    
    my $unpsize;
    if ($len == 1) {
        $unpsize = "C";
    }
    elsif ($len == 2) {
        $unpsize = "S";
    }
    else {
        $unpsize = "I";
    }
 
    seek(BIN, $off, 0);
    my $c = read(BIN, $ret, $len);# or die "off: $off $! ($ret)";
    return ($c > 0 ? sprintf("%0".$len."x", unpack($unpsize, $ret)) : '???');
}

sub get_num {
    my $off = shift;
    my $len = shift;
    my $ret;
    
    my $unpsize;
    if ($len == 1) {
        $unpsize = "C";
    }
    elsif ($len == 2) {
        $unpsize = "S";
    }
    else {
        $unpsize = "I";
    }
 
    seek(BIN, $off, 0);
    my $c = read(BIN, $ret, $len);# or die "off: $off $! ($ret)";
    return ($c > 0 ? unpack($unpsize, $ret) : 0);
}

sub get_regcmp {
    # try to work out the number of jumptable elements based on the register
    # and previous instructions
    # (method is not 100% reliable)
    local $found1, $found2, $add;
    $add = -1;
    foreach(@hist) {
        # determine condition flag used in the nearest branch instruction
        # only encountered 'cs' or 'hi' so far, depending on compiler
        if ($add < 0) {
            $found1 = $_ =~ /^.*\tb(..).*\t.+/;
            if ($1 eq "cs") {
                $add = 0;
            }
            elsif ($1 eq "hi") {
                $add = 1;
            }
        }
        $found2 = $_ =~ /^.*\tcmp.*\t$_[0], #([[:digit:]]+)/;
        if ($found2) {
            if ($add<0) {
                $add = 0;
            }
            return $1 + $add;
        }
    }
    return 0;
}

sub get_regcmp2 {
    # try to work out the number of jumptable elements based on the register
    # and previous instructions
    # (method is not 100% reliable)
    # assumes bcs instruction after cmp
    local $found1, $ret;
    foreach(@hist) {
        $found1 = $_ =~ /^.*\tcmp.*\t$_[0], #(0x)*([[:xdigit:]]+)/;
        if ($found1) {
            if ($1 ne "") {
                $ret = hex($2);
            }
            else {
                $ret = $2
            }
            return $ret;
        }
    }
    return 0;
}
