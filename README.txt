 mod_push_sender - Post push notifications to an endpoint for offline users
                    Requires: ejabberd 19.08 or higher
                    Homepage: https://github.com/codeliter/mod_push_sender
                    Author: Codeliter


mod_push_sender
===============
Measures several statistics. It provides a new section in ejabberd
Web Admin and two ejabberd commands to view the information.

CONFIGURATION
=============
Enable the module in ejabberd.yml for example with a basic configuration:
modules:
  mod_push_sender: {}

Configurable options:
  post_url: This is the url we want to send an HTTP POST request.

  token: The access token required by the endpoint to honour your request.

    EXAMPLE CONFIGURATION
    --------------------
    modules:
        mod_push_sender:
            post_url: "http://push.service.com/send"
            token: "xxxx-xxxx"