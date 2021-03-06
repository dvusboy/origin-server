#!/usr/bin/env oo-ruby
#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++
#
# Test the OpenShift application_container model
#
module OpenShift
  ;
end

require 'test_helper'
require 'openshift-origin-node/model/application_container'
require 'openshift-origin-node/model/application_repository'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/model/default_builder'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common'
require 'test/unit'
require 'fileutils'
require 'yaml'
require 'mocha'

class BuildLifecycleTest < Test::Unit::TestCase

  def setup
    # Set up the config
    @config = mock('OpenShift::Config')

    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")

    OpenShift::Config.stubs(:new).returns(@config)

    # Set up the container
    @gear_uuid = "501"
    @user_uid  = "501"
    @app_name  = 'UnixUserTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip   = "127.0.0.1"

    OpenShift::ApplicationContainer.stubs(:get_build_model).returns(:v2)
    @cartridge_model = mock()
    OpenShift::V2CartridgeModel.stubs(:new).returns(@cartridge_model)

    @state = mock()
    OpenShift::Utils::ApplicationState.stubs(:new).returns(@state)

    @container = OpenShift::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
        @app_name, @gear_uuid, @namespace, nil, nil, nil)
  end

  def test_pre_receive_default_builder
    @cartridge_model.expects(:builder_cartridge).returns(nil)

    @container.expects(:stop_gear).with(user_initiated: true, out: $stdout, err: $stderr)

    @container.pre_receive(out: $stdout, err: $stderr)
  end

  def test_post_receive_default_builder
    repository = mock()
    OpenShift::ApplicationRepository.expects(:new).returns(repository)

    @cartridge_model.expects(:builder_cartridge).returns(nil)

    repository.expects(:deploy)
    @container.expects(:build).with(out: $stdout, err: $stderr)
    @container.expects(:start_gear).with(secondary_only: true, user_initiated: true, out: $stdout, err: $stderr)
    @container.expects(:deploy).with(out: $stdout, err: $stderr)
    @container.expects(:start_gear).with(primary_only: true, user_initiated: true, out: $stdout, err: $stderr)
    @container.expects(:post_deploy).with(out: $stdout, err: $stderr)

    @container.post_receive(out: $stdout, err: $stderr)
  end

  def test_pre_receive_builder_cart
    builder = mock()
    @cartridge_model.expects(:builder_cartridge).returns(builder)

    @cartridge_model.expects(:do_control).with('pre-receive', builder, out: $stdout, err: $stderr)

    @container.pre_receive(out: $stdout, err: $stderr)
  end

  def test_post_receive_builder_cart
    builder = mock()
    @cartridge_model.expects(:builder_cartridge).returns(builder)

    @cartridge_model.expects(:do_control).with('post-receive', builder, out: $stdout, err: $stderr)

    @container.post_receive(out: $stdout, err: $stderr)
  end

  def test_build_success
    @state.expects(:value=).with(OpenShift::State::BUILDING)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary).twice

    @cartridge_model.expects(:do_control).with('pre-build',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                          .returns('pre-build|')

    @cartridge_model.expects(:do_control).with('build',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('build')

    output = @container.build(out: $stdout, err: $stderr)

    assert_equal "pre-build|build", output
  end

  def test_deploy_no_web_proxy_success
    @state.expects(:value=).with(OpenShift::State::DEPLOYING)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)
    @cartridge_model.expects(:web_proxy).returns(nil)

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('deploy')

    output = @container.deploy(out: $stdout, err: $stderr)

    assert_equal "deploy", output
  end

  def test_deploy_web_proxy_success
    @state.expects(:value=).with(OpenShift::State::DEPLOYING)

    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)
    proxy = mock()
    @cartridge_model.expects(:web_proxy).returns(proxy)

    @cartridge_model.expects(:do_control).with('deploy',
                                               proxy,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('deploy')

    @cartridge_model.expects(:do_control).with('deploy',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('deploy')

    output = @container.deploy(out: $stdout, err: $stderr)

    assert_equal "deploy", output
  end

  def test_post_deploy_success
    primary = mock()
    @cartridge_model.expects(:primary_cartridge).returns(primary)

    @cartridge_model.expects(:do_control).with('post-deploy',
                                               primary,
                                               pre_action_hooks_enabled: false,
                                               prefix_action_hooks:      false,
                                               out:                      $stdout,
                                               err:                      $stderr)
                                           .returns('post-deploy')

    output = @container.post_deploy(out: $stdout, err: $stderr)

    assert_equal "post-deploy", output
  end

  def test_remote_deploy_success
    @container.expects(:start_gear).with(secondary_only: true, user_initiated: true, out: $stdout, err: $stderr)
    @container.expects(:deploy).with(out: $stdout, err: $stderr)
    @container.expects(:start_gear).with(primary_only: true, user_initiated: true, out: $stdout, err: $stderr)
    @container.expects(:post_deploy).with(out: $stdout, err: $stderr)

    @container.remote_deploy(out: $stdout, err: $stderr)
  end
end
