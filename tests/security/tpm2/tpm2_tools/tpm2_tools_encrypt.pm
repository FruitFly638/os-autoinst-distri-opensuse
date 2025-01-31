# Copyright 2020 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Summary: Per TPM2 stack, we would like to add the tpm2-tools tests,
#          from sles15sp2, update tpm2.0-tools to the stable 4 release
#          this test module will cover encrypt and decrypt tests.
# Maintainer: rfan1 <richard.fan@suse.com>
# Tags: poo#64905, tc#1742297

use strict;
use warnings;
use base 'opensusebasetest';
use testapi;

sub run {
    my $self = shift;
    $self->select_serial_terminal;

    # Write/Read data to/from a Non-Volatile (NV) index
    my $test_dir = "tpm2_tools_encrypt";
    my $test_file = "nv.test_w";
    assert_script_run "mkdir $test_dir";
    assert_script_run "cd $test_dir";
    assert_script_run "tpm2_nvdefine -Q  1 -C o -s 32 -a \"ownerread|policywrite|ownerwrite\" -T tabrmd";
    validate_script_output "tpm2_nvreadpublic -T tabrmd", sub { m/0x1000001/ };
    assert_script_run "echo \"please123abc\" > $test_file";
    assert_script_run "tpm2_nvwrite -Q  1 -C o -i $test_file -T tabrmd";
    assert_script_run "tpm2_nvread -Q  1 -C o -s 32 -o 0 -T tabrmd";

    # tpm2_nvundefine(1) - Delete a Non-Volatile (NV) index
    assert_script_run "tpm2_nvundefine -Q  1 -C o -T tabrmd";
    validate_script_output "tpm2_nvreadpublic -T tabrmd|wc -l", sub { m/0/ };

    # Create an ECC primary object
    my $context_out = "context.out";
    my $key_priv = "key.priv";
    my $key_pub = "key.pub";
    my $key_ctx = "key.ctx";
    assert_script_run "tpm2_createprimary -C o -g sha256 -G ecc -c $context_out -T tabrmd";

    # tpm2_create(1) - Create a child objec
    assert_script_run "tpm2_create -C $context_out -G rsa2048:rsaes -u $key_pub -r $key_priv -T tabrmd";

    # tpm2_load(1) - Load both the private and public portions of an object into the TPM
    assert_script_run "tpm2_load  -C $context_out -u $key_pub -r $key_priv -c $key_ctx -T tabrmd";

    # Encrypt using RSA
    my $msg_dat = "msg.dat";
    my $msg_enc = "msg.enc";
    assert_script_run "echo \"my message\" > $msg_dat";
    assert_script_run "tpm2_rsaencrypt -c $key_ctx -o $msg_enc $msg_dat -T tabrmd";

    # Decrypt using RSA
    my $msg_ptext = "msg.ptext";
    assert_script_run "tpm2_rsadecrypt -c $key_ctx -o $msg_ptext $msg_enc -T tabrmd";
    assert_script_run "diff $msg_dat $msg_ptext";
    assert_script_run "cd";
}

sub test_flags {
    return {always_rollback => 1};
}

1;
