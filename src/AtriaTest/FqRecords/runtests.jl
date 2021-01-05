
@noinline function test_fqrecords()

    r = fqreadrecord("@SRR7243169.1 1 length=301
ACCCAAGGCGTGCTCGTAGGATTTGTCGACATAGTCGATCAGACCTTCGTCCAGCGGCCAGGCGTTAACCTGACCTTCCCAATCGTCGATGATGGTGTTGCCGAAGCGGAACACTTCACTTTGCAGGTACGGCACGCGCGCGGCGACCCAGGCAGCCTTGGCGGCTTTCAGGGTCTCGGCGTTCGGCCTGTCTCTTATACACATCTCCGAGCCCACGAGCCGTAGAGGAATCTCGTATGCCGTCTTCTGCTTGAAAAAAAAAGACAAGCACTCTATACATCCGTCTCACCCGATACACTCC
+SRR7243169.1 1 length=301
CCCCCGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGFGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGDGGGGGGDGGGGGGGGCGGGGGGGGGGGGGGGGFGGGGGGFGGGGGGGGGGGGGGFGGGEDGG>GFFGGGGDGGGDGFGG7;)9C>DF3B4)76676:@DF?F?>D@F3=FFFF?=<6*600)07).)0.)818)))**0=***))0((.**)0))0.7*/62(
")

    r2 = fqreadrecord("@SRR7243169.1 1 length=301
GCCGAANNCCGAGACCCTGAAAGCCGCCAAGGCTGCCTGGGTCGCCGCGCGCGTGCCGTACCTGCAAAGTGAAGTGTTCCGCTTCGGCAACACCATCATCGACGATTGGGAAGGTCAGGTTAACGCCTGGCCGCTGGACGAAGGTCTGATCGACTATGTCGACAAATCCTACGAGCACGCCTTGGGTCTGTCTCTTATACACCTCTGACGCTGCCGACGATACCCCCTGTGTCACACTTCGCAGTCGACGTCTCCGTAACAAAAACTCAGAAGTATACACTAGAATACTACGTAGGATATC
+SRR7243169.1 1 length=301
CCCCCG##GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGDGGGGGGGGGGGGGGGGFGGGGGGGGGGGFGGGGGGGGGGGGGGGGGGGGGGEDGGGGGFGGGGGGGGGFFFCFGGDGGCGFDCCEC>E>EGGGG7EFGGFGGEEE9FFGFFEDGGDFGGGGG**9DDDCEFDFDD5CFD>**::C699FG><57*)7FBDB3)8>>@>EB>:9)7)5)))1**8*))**.)))0)))))0000*).50.19)08().4)))..).64-))5).)).-)-)(().(+++++
")

    r1 = deepcopy(r)

    fqreadrecord!(r, IOBuffer("@SRR7243169.1 1 length=301
GCCGAANNCCGAGACCCTGAAAGCCGCCAAGGCTGCCTGGGTCGCCGCGCGCGTGCCGTACCTGCAAAGTGAAGTGTTCCGCTTCGGCAACACCATCATCGACGATTGGGAAGGTCAGGTTAACGCCTGGCCGCTGGACGAAGGTCTGATCGACTATGTCGACAAATCCTACGAGCACGCCTTGGGTCTGTCTCTTATACACCTCTGACGCTGCCGACGATACCCCCTGTGTCACACTTCGCAGTCGACGTCTCCGTAACAAAAACTCAGAAGTATACACTAGAATACTACGTAGGATATC
+SRR7243169.1 1 length=301
CCCCCG##GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGDGGGGGGGGGGGGGGGGFGGGGGGGGGGGFGGGGGGGGGGGGGGGGGGGGGGEDGGGGGFGGGGGGGGGFFFCFGGDGGCGFDCCEC>E>EGGGG7EFGGFGGEEE9FFGFFEDGGDFGGGGG**9DDDCEFDFDD5CFD>**::C699FG><57*)7FBDB3)8>>@>EB>:9)7)5)))1**8*))**.)))0)))))0000*).50.19)08().4)))..).64-))5).)).-)-)(().(+++++
"))

    @test r == r2

    fqwriterecord(stdout, r1)

    @test  isinreadlength!(r, 301:301)
    @test !isinreadlength!(r, 301:300)

    @test count_N(r1) == 0.0
    @test count_N(r2) == 2.0

    @test  isnotmuchN!(r1, r2, 2)
    @test !isnotmuchN!(r1, r2, 1)

    front_trim!(r, 20)
    @test r.seq.data != r2.seq.data # if this failed, front_trim! might affect other functions, such as pe_consensus, copyto!, safe_copyto!, bitwise_scan, bitwise_scan_rc!, etc.


    tail_trim!(r, 100)
    @test r2.seq[21:120] == r.seq
    @test isbitsafe(r2.seq)
    @test r.seq.data[7] == 0x0000000000008441

    @test qualitymatch(r2, UInt8(38), UInt(38*5), 5) == -1
    @test qualitymatch(r2, UInt8(45), UInt(45*5), 5) == 226

    r1_seq_rc = reverse_complement(r1.seq)
    r2_seq_rc = reverse_complement(r2.seq)

    is_consensused, ratio_mismatch = pe_consensus!(r1, r2, r1_seq_rc, r2_seq_rc)
    @test is_consensused == false
    @test 0.75 < ratio_mismatch < 0.77

    r1= fqreadrecord("@SRR7243169.1 1 length=301
ACCCAAGGCGTGCTCGTAGGATTTGTCGACATAGTCGATCAGACCTTCGTCCAGCGGCCAGGCGTTAACCTGACCTTCCCAATCGTCGATGATGGTGTTGCCGAAGCGGAACACTTCACTTTGCAGGTACGGCACGCGCGCGGCGACCCAGGCAGCCTTGGCGGCTTTCAGGGTCTCGGCGTTCGGCCTGTCTCTTATACACATCTCCGAGCCCACGAGCCGTAGAGGAATCTCGTATGCCGTCTTCTGCTTGAAAAAAAAAGACAAGCACTCTATACATCCGTCTCACCCGATACACTCC
+SRR7243169.1 1 length=301
CCCCCGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGFGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGDGGGGGGDGGGGGGGGCGGGGGGGGGGGGGGGGFGGGGGGFGGGGGGGGGGGGGGFGGGEDGG>GFFGGGGDGGGDGFGG7;)9C>DF3B4)76676:@DF?F?>D@F3=FFFF?=<6*600)07).)0.)818)))**0=***))0((.**)0))0.7*/62(
")

    r2 = fqreadrecord("@SRR7243169.1 1 length=301
GCCGAANNCCGAGACCCTGAAAGCCGCCAAGGCTGCCTGGGTCGCCGCGCGCGTGCCGTACCTGCAAAGTGAAGTGTTCCGCTTCGGCAACACCATCATCGACGATTGGGAAGGTCAGGTTAACGCCTGGCCGCTGGACGAAGGTCTGATCGACTATGTCGACAAATCCTACGAGCACGCCTTGGGTCTGTCTCTTATACACCTCTGACGCTGCCGACGATACCCCCTGTGTCACACTTCGCAGTCGACGTCTCCGTAACAAAAACTCAGAAGTATACACTAGAATACTACGTAGGATATC
+SRR7243169.1 1 length=301
CCCCCG##GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGDGGGGGGGGGGGGGGGGFGGGGGGGGGGGFGGGGGGGGGGGGGGGGGGGGGGEDGGGGGFGGGGGGGGGFFFCFGGDGGCGFDCCEC>E>EGGGG7EFGGFGGEEE9FFGFFEDGGDFGGGGG**9DDDCEFDFDD5CFD>**::C699FG><57*)7FBDB3)8>>@>EB>:9)7)5)))1**8*))**.)))0)))))0000*).50.19)08().4)))..).64-))5).)).-)-)(().(+++++
")
    r1_seq_rc = reverse_complement(r1.seq)
    r2_seq_rc = reverse_complement(r2.seq)

    is_consensused, ratio_mismatch = pe_consensus!(r1, r2, r2_seq_rc, 187)
    @test is_consensused == true
    @test count_N(r2) == 0.0  # r2's Ns were fixed.
    @test r1_seq_rc[301-187+1:end] == r2.seq[1:187] # r2's Ns were fixed.

    r1= fqreadrecord("@SRR7243169.1 1 length=301
ACCCAAGGCGTGCTCGTAGGATTTGTCGACATAGTCGATCAGACCTTCGTCCAGCGGCCAGGCGTTAACCTGACCTTCCCAATCGTCGATGATGGTGTTGCCGAAGCGGAACACTTCACTTTGCAGGTACGGCACGCGCGCGGCGACCCAGGCAGCCTTGGCGGCTTTCAGGGTCTCGGCGTTCGGCCTGTCTCTTATACACATCTCCGAGCCCACGAGCCGTAGAGGAATCTCGTATGCCGTCTTCTGCTTGAAAAAAAAAGACAAGCACTCTATACATCCGTCTCACCCGATACACTCC
+SRR7243169.1 1 length=301
CCCCCGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGFGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGDGGGGGGDGGGGGGGGCGGGGGGGGGGGGGGGGFGGGGGGFGGGGGGGGGGGGGGFGGGEDGG>GFFGGGGDGGGDGFGG7;)9C>DF3B4)76676:@DF?F?>D@F3=FFFF?=<6*600)07).)0.)818)))**0=***))0((.**)0))0.7*/62(
")

    r2 = fqreadrecord("@SRR7243169.1 1 length=301
GCCGAANNCCGAGACCCTGAAAGCCGCCAAGGCTGCCTGGGTCGCCGCGCGCGTGCCGTACCTGCAAAGTGAAGTGTTCCGCTTCGGCAACACCATCATCGACGATTGGGAAGGTCAGGTTAACGCCTGGCCGCTGGACGAAGGTCTGATCGACTATGTCGACAAATCCTACGAGCACGCCTTGGGTCTGTCTCTTATACACCTCTGACGCTGCCGACGATACCCCCTGTGTCACACTTCGCAGTCGACGTCTCCGTAACAAAAACTCAGAAGTATACACTAGAATACTACGTAGGATATC
+SRR7243169.1 1 length=301
CCCCCG##GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGDGGGGGGGGGGGGGGGGFGGGGGGGGGGGFGGGGGGGGGGGGGGGGGGGGGGEDGGGGGFGGGGGGGGGFFFCFGGDGGCGFDCCEC>E>EGGGG7EFGGFGGEEE9FFGFFEDGGDFGGGGG**9DDDCEFDFDD5CFD>**::C699FG><57*)7FBDB3)8>>@>EB>:9)7)5)))1**8*))**.)))0)))))0000*).50.19)08().4)))..).64-))5).)).-)-)(().(+++++
")
    tail_trim!(r1, 187) # after 187 is adapters
    tail_trim!(r2, 187)
    r1_seq_rc = reverse_complement(r1.seq)
    r2_seq_rc = reverse_complement(r2.seq)

    is_consensused, ratio_mismatch = pe_consensus!(r1, r2, r1_seq_rc, r2_seq_rc)
    @test is_consensused == true
    @test ratio_mismatch == 0.0
    @test count_N(r2) == 0.0  # r2's Ns were fixed.
    @test r1_seq_rc == r2.seq # r2's Ns were fixed.

    true
end
