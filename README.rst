Advanced Message Queuing Protocol
=================================
Setup for Arch Linux
--------------------
#. ``$ packer rabbitmq``
#. Changed ``NODENAME`` to ``rachael`` in ``/etc/rabbitmq/rabbitmq-env.conf``
#. ``# rabbitmqctl adduser github <password>``
#. ``# rabbitmqctl add_vhost github``
#. ``# rabbitmqctl set_permissions -p github github ".*" ".*" ".*"``
#. ``tail -f /var/log/rabbitmq/rachael.log`` - keep it open to see results of the next step
#. On github-- administration settings for the repo, service hooks, amqp -> fill that shit out... test hook
#. if all went well: **profit.**

:Notes:
        I tried enabling the manager web interface but ran into some problems...
        When I ran ``# rabbitmq-plugins enable rabbitmq_management`` I got::

                Error: {cannot_write_enabled_plugins_file,"/etc/rabbitmq/enabled_plugins",
                        eaccess}

        If I ``# touch /etc/rabbitmq/enabled_plugins`` and try to enable the plugin again, I get::
                
               Error: {'EXIT',{{case_clause,{ok,[]}},
                [{rabbit_plugins,read_enabled_plugins,1},
                 {rabbit_plugins,action,5},
                 {rabbit_plugins,start,0},
                 {init,start_it,1},
                 {init,start_em,1}]}}
        Needed to to put ``[].`` in the ``enabled_plugins`` file and needed to ``chmod o+r``, then was able to restart the server and gain access to the management interface.
