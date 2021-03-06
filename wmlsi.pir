# Copyright (C) 2006-2009, Parrot Foundation.
# $Id$

=head1 WMLScript Interpreter

=head2 Synopsis

 parrot-wmlsi file.wmlsc function [params ...]

=head2 Description

B<wmlsi> translates a WMLScript bytecode file to Parrot PBC and calls
C<function(params, ...)>.

=head2 See Also

parrot-wmlsd

=cut

.HLL 'wmlscript'

.sub 'main' :main
    .param pmc argv
    load_language 'wmlscript'
    .local int argc
    .local string progname
    .local string filename
    .local string entryname
    .local string content
    argc = elements argv
    if argc < 3 goto USAGE
    progname = shift argv
    filename = shift argv
    entryname = shift argv
    content = load_script(filename)
    unless content goto L1
    .local pmc loader
    .local pmc script
    new loader, 'WmlsBytecode'
    push_eh _handler
    script = loader.'load'(content)
    script['filename'] = filename
    .local string gen_pir
    gen_pir = script.'translate'()
    .local pmc pir_comp
    .local pmc pbc_out
    pir_comp = compreg 'PIR'
    pbc_out = pir_comp(gen_pir)
    $P0 = pbc_out[0]    # __onload
    $P0()
    .local pmc params
    new params, 'ResizablePMCArray'
  L2:
    unless argv goto L3
    $S0 = shift argv
    new $P0, 'WmlsString'
    $P0 = $S0
    push params, $P0
    goto L2
  L3:
    .local pmc entry
    $S0 = filename
    $S0 .= ':'
    $S0 .= entryname
    entry = get_hll_global $S0
    unless null entry goto L4
    print $S0
    print " not found.\n"
    end
  L4:
    entry(params :flat)
    pop_eh
  L1:
    end
  USAGE:
    .local pmc stderr
    stderr = getstderr
    print stderr, "Usage: parrot wmlsi.pbc filename entry\n"
    exit -1
  _handler:
    .local pmc e
    .local string msg
    .get_results (e)
    msg = e
    say msg
    end
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
