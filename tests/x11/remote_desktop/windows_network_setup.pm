# SUSE's openQA tests
#
# Copyright 2018-2021 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Remote Login: Windows access openSUSE/SLE over RDP
# Maintainer: GraceWang <gwang@suse.com>
# Tags: tc#1610388

use strict;
use warnings;
use base 'x11test';
use testapi;
use lockapi;

sub run {
    my $self = shift;

    send_key "super-x";
    assert_and_click "windows-powershell-admin";
    assert_and_click "windows-powershell-yes";

    assert_and_click "powershell-started", timeout => 120;
    type_string "netsh interface ip set address name=Ethernet static 10.0.2.18 255.255.255.0 10.0.2.2";
    send_key "ret";

    assert_screen "network-allow-discovered";
    assert_and_click "network-discovered-yes";

    sleep 5;
    type_string "netsh interface ip set dns Ethernet static 10.67.0.2";
    send_key "ret";

    type_string "ping 10.0.2.2";
    send_key "ret";
    type_string "exit";
    send_key "ret";
}
1;
