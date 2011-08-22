#
# Learning switch application that supports multiple switches
#
# Author: Yasuhito Takamiya <yasuhito@gmail.com>
#
# Copyright (C) 2008-2011 NEC Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

#
# Multi learning switch with memcached
#
# Author: Kazushi SUGYO
#


$LOAD_PATH << "../apps/learning_switch_memcached/"


require "forwarding-db"


#
# A OpenFlow controller class that emulates multiple layer-2 switches.
#
class MultiLearningSwitch < Trema::Controller


  def start
    @fdbs = Hash.new do | hash, datapath_id |
      hash[ datapath_id ] = ForwardingDB.new datapath_id.to_s
    end
  end


  def packet_in datapath_id, message
    fdb = @fdbs[ datapath_id ]
    fdb.learn message.macsa, message.in_port
    port_no = fdb.port_no_of( message.macda )
    if port_no
      flow_mod datapath_id, message, port_no
      packet_out datapath_id, message, port_no
    else
      flood datapath_id, message
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def flow_mod datapath_id, message, port_no
    send_flow_mod_add(
      datapath_id,
      :match => ExactMatch.from( message ),
      :actions => Trema::ActionOutput.new( port_no )
    )
  end


  def packet_out datapath_id, message, port_no
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => Trema::ActionOutput.new( port_no )
    )
  end


  def flood datapath_id, message
    packet_out datapath_id, message, OFPP_FLOOD
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End: