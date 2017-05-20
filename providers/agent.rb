#
# Cookbook Name:: rancher-ng
# Provider:: rancher_ng_agent
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
  docker_image new_resource.image do
    tag new_resource.version
    action :pull
  end

  docker_container new_resource.name do
    image new_resource.image
    tag new_resource.version
    command "#{ new_resource.auth_url }"
    volumes ['/var/run/docker.sock:/var/run/docker.sock', new_resource.mount_point]
    container_name new_resource.name
    env "CATTLE_AGENT_IP=\"#{ node['ipaddress'] }\""
    autoremove new_resource.autoremove
    privileged new_resource.privileged
    not_if "docker inspect #{new_resource.name}"
  end
end

def rancher_delete(new_resource)
  docker_container new_resource.name do
    action :delete
  end
end