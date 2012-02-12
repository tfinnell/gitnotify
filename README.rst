Gitnotify
=========
Triggers a pop-up notification when a message is received from AMQP queue.

There's a bit to configure here if you're starting from scratch... but, if you already have an AMQP broker configured to your taste, edit ``broker.yaml`` with your credentials and run ``gitnotify.rb``. Once you enable Githubs AMQP service hook you should be getting notifications when someone pushes to your repository.

Advanced Message Queuing Protocol
---------------------------------
Setup for Arch Linux
~~~~~~~~~~~~~~~~~~~~
#. Install rabbitmq from the aur with ``$ packer rabbitmq``
#. You can change ``NODENAME`` in ``/etc/rabbitmq/rabbitmq-env.conf`` if desired
#. Install the rabbitmq management interface with ``# rabbitmq-plugins enable rabbitmq_management``
#. Run the rabbitmq start script
#. Add a new user or two and get rid of the guest account
#. Create a new Virtual host eg. ``github``
#. Create a new Queue using the virutal host you just created eg. ``github``
#. Create a new Exchange with the queue you just created that is type ``topic`` or ``fanout``
#. Click on the new exchange you just created and add a binding to the queue you created with the routing key ``github.#`` if you created.
#. On Github's site: go to administration settings for your repository -> service hooks, amqp -> fill out the form... click test hook... you should see a new message in your queue...

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
