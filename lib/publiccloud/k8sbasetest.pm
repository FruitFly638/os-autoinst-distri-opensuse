# SUSE's openQA tests
#
# Copyright 2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Base class for publiccloud tests
#
# Maintainer: qa-c team <qa-c@suse.de>

package publiccloud::k8sbasetest;
use Mojo::Base 'publiccloud::basetest';
use utils 'script_retry';
use testapi;
use warnings;
use strict;
use utils qw(random_string);

=head2 install_kubectl
Install kubectl from the k8s page
=cut
sub install_kubectl {
    my $version = get_var('PUBLICCLOUD_KUBECTL_VERSION', 'v1.22.2');
    assert_script_run("curl -LO https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl");
    assert_script_run("chmod a+x kubectl");
    assert_script_run("rm /usr/bin/kubectl");
    assert_script_run("mv kubectl /usr/bin/kubectl");
}

=head2 apply_manifest
Apply a kubernetes manifest
=cut
sub apply_manifest {
    my ($self, $manifest) = @_;

    my $path = sprintf('/tmp/%s.yml', random_string(32));

    script_output("echo -e '$manifest' > $path");
    upload_logs($path, failok => 1);

    assert_script_run("kubectl apply -f $path");
}

=head2 find_pods
Find pods using kubectl queries
=cut
sub find_pods {
    my ($self, $query) = @_;
    return script_output("kubectl get pods --no-headers -l $query -o custom-columns=':metadata.name'");
}

=head2 wait_for_job_complete
Wait until the job is complete
=cut
sub wait_for_job_complete {
    my ($self, $job) = @_;
    assert_script_run("kubectl wait --for=condition=complete --timeout=60s job/$job");
}

=head2 validate_log
Validates that the logs contains a text
=cut
sub validate_log {
    my ($self, $pod, $text) = @_;
    validate_script_output("kubectl logs $pod 2>&1", qr/$text/);
}
1;
