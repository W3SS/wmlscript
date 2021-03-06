#!/usr/bin/env parrot
# Copyright (C) 2009, Parrot Foundation.

=head1 NAME

setup.pir - Python distutils style

=head1 DESCRIPTION

No Configure step, no Makefile generated.

=head1 USAGE

    $ parrot setup.pir build
    $ parrot setup.pir test
    $ sudo parrot setup.pir install

=cut

.sub 'main' :main
    .param pmc args
    $S0 = shift args
    load_bytecode 'distutils.pbc'

    .const 'Sub' prebuild = 'prebuild'
    register_step_before('build', prebuild)

    .const 'Sub' clean = 'clean'
    register_step_before('clean', clean)

    .const 'Sub' testclean = 'testclean'
    register_step_after('test', testclean)
    register_step_after('clean', testclean)

    .const 'Sub' pmctest = 'pmctest'
    register_step('pmctest', pmctest)

    $P0 = new 'Hash'
    $P0['name'] = 'WMLScript'
    $P0['abstract'] = 'WMLScript Bytecode Translator'
    $P0['authority'] = 'http://github.com/fperrad'
    $P0['description'] = 'WMLScript Bytecode Translator'
    $P5 = split ',', 'wmlscript,wap'
    $P0['keywords'] = $P5
    $P0['license_type'] = 'Artistic License 2.0'
    $P0['license_uri'] = 'http://www.perlfoundation.org/artistic_license_2_0'
    $P0['copyright_holder'] = 'Parrot Foundation'
    $P0['checkout_uri'] = 'git://github.com/fperrad/wmlscript.git'
    $P0['browser_uri'] = 'http://github.com/fperrad/wmlscript'
    $P0['project_uri'] = 'http://github.com/fperrad/wmlscript'

    # build
    $P1 = new 'Hash'
    $P1['wmls_ops'] = 'dynext/ops/wmls.ops'
    $P0['dynops'] = $P1

    $P2 = new 'Hash'
    $P3 = split "\n", <<'SOURCES'
dynext/pmc/wmlsinteger.pmc
dynext/pmc/wmlsfloat.pmc
dynext/pmc/wmlsstring.pmc
dynext/pmc/wmlsboolean.pmc
dynext/pmc/wmlsinvalid.pmc
dynext/pmc/wmlsbytecode.pmc
SOURCES
    $S0 = pop $P3
    $P2['wmls_group'] = $P3
    $P0['dynpmc'] = $P2

    $P4 = new 'Hash'
    $P5 = split "\n", <<'SOURCES'
wmlscript/WMLScript.pir
wmlscript/script.pir
wmlscript/wmlsstdlibs.pir
wmlscript/opcode.pir
wmlscript/stdlibs.pir
SOURCES
    $S0 = pop $P5
    $P4['wmlscript/wmlscript.pbc'] = $P5
    $P4['wmlscript/library/wmlslang.pbc'] = 'wmlscript/library/wmlslang.pir'
    $P4['wmlscript/library/wmlsfloat.pbc'] = 'wmlscript/library/wmlsfloat.pir'
    $P4['wmlscript/library/wmlsstring.pbc'] = 'wmlscript/library/wmlsstring.pir'
    $P4['wmlscript/library/wmlsconsole.pbc'] = 'wmlscript/library/wmlsconsole.pir'
    $P4['wmlsi.pbc'] = 'wmlsi.pir'
    $P4['wmlsd.pbc'] = 'wmlsd.pir'
    $P0['pbc_pir'] = $P4

    $P6 = new 'Hash'
    $P6['parrot-wmlsi'] = 'wmlsi.pbc'
    $P6['parrot-wmlsd'] = 'wmlsd.pbc'
    $P0['installable_pbc'] = $P6

    # test
    $S0 = get_parrot()
    $P0['prove_exec'] = $S0
    $P0['prove_files'] = 't/pmc/*.t t/*.t'

    # install
    $P7 = split "\n", <<'LIBS'
wmlscript/wmlscript.pbc
wmlscript/library/wmlslang.pbc
wmlscript/library/wmlsfloat.pbc
wmlscript/library/wmlsstring.pbc
wmlscript/library/wmlsconsole.pbc
LIBS
    $S0 = pop $P7
    $P0['inst_lang'] = $P7

    # dist
    $P8 = glob('wmls2p*.pir t/helpers.pir build/*.pl build/SRM/*.pm wmlscript/translation.rules wmlscript/wmlslibs.cfg')
    $P0['manifest_includes'] = $P8
    $P9 = split ' ', 'wmlscript/opcode.pir wmlscript/stdlibs.pir'
    $P0['manifest_excludes'] = $P9
    $P10 = split ' ', 'CREDITS MAINTAINER README'
    $P0['doc_files'] = $P10

    .tailcall setup(args :flat, $P0 :flat :named)
.end

.sub 'prebuild' :anon
    .param pmc kv :slurpy :named
    .local string cmd, srm
    srm = 'Stack'
    $P0 = split "\n", <<'SOURCES'
wmlscript/translation.rules
build/translator.pl
build/SRM/Stack.pm
build/SRM/Register.pm
SOURCES
    $S0 = pop $P0
    $I0 = newer('wmlscript/opcode.pir', $P0)
    if $I0 goto L1
    cmd = 'perl build/translator.pl'
    cmd .= ' --output wmlscript/opcode.pir'
    cmd .= ' --srm '
    cmd .= srm
    cmd .= ' wmlscript/translation.rules'
    system(cmd, 1 :named('verbose'))
  L1:

    $P0 = split ' ', 'wmlscript/wmlslibs.cfg build/stdlibs.pl'
    $I0 = newer('wmlscript/stdlibs.pir', $P0)
    if $I0 goto L2
    cmd = 'perl build/stdlibs.pl'
    cmd .= ' --output wmlscript/stdlibs.pir'
    cmd .= ' wmlscript/wmlslibs.cfg'
    system(cmd, 1 :named('verbose'))
  L2:
.end

.sub 'clean' :anon
    .param pmc kv :slurpy :named
    unlink('wmlscript/opcode.pir', 1 :named('verbose'))
    unlink('wmlscript/stdlibs.pir', 1 :named('verbose'))
.end

.sub 'testclean' :anon
    .param pmc kv :slurpy :named
    system("perl -MExtUtils::Command -e rm_f test_*.wmls test_*.wmlsc")
.end

.sub 'pmctest' :anon
    .param pmc kv :slurpy :named
    run_step('build', kv :flat :named)

    $P0 = glob('t/pmc/*.t')
    $P0 = sort_strings($P0)
    $S0 = get_parrot()
    runtests($P0 :flat, $S0 :named('exec'))
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
