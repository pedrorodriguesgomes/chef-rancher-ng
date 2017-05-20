#
# Cookbook Name:: rancher-ng
# Provider:: rancher_ng_server
#
# Copyright (C) 2017 Alexander Merkulov
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use_inline_resources

action :create do
  rancher_create(new_resource)

  new_resource.updated_by_last_action(true)
end

action :delete do
  rancher_delete(new_resource)

  new_resource.updated_by_last_action(true)
end

def rancher_create(new_resource)
  directory new_resource.db_dir do
    mode '0755'
  end

  docker_image new_resource.image do
    tag new_resource.version
    action :pull
  end

  if external_db?(new_resource)
    container_with_external_db(new_resource)
  else
    container(new_resource)
  end
end

def rancher_delete(new_resource)
  docker_container new_resource.name do
    action :delete
  end
end

def container_with_external_db(new_resource)
  container(new_resource, get_command(new_resource))
end

def container(new_resource, cmd=nil)
  docker_container new_resource.name do
    repo new_resource.image
    tag new_resource.version
    command cmd unless cmd.nil?
    port "#{new_resource.port}:8080"
    detach new_resource.detach
    container_name new_resource.name
    restart_policy new_resource.restart_policy
    volumes [ "#{ new_resource.db_dir }:/var/lib/mysql" ]
    action :run
  end
end

def external_db?(new_resource)
  new_resource.external_db && validate_db_args(new_resource)
end

def validate_db_args?(new_resource)
  [
    new_resource.db_host,
    new_resource.db_port,
    new_resource.db_user,
    new_resource.db_pass,
    new_resource.db_name
  ].all? { |val| !val.nil? }
end

def gen_command(new_resource)
  [
    "--db-host #{new_resource.db_host}",
    "--db-port #{new_resource.db_port}",
    "--db-user #{new_resource.db_user}",
    "--db-pass #{new_resource.db_pass}",
    "--db-name #{new_resource.db_name}"
  ].join(' ')
end