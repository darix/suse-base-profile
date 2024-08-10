ssh:
  PermitRootLogin:                 prohibit-password
  Protocol:                        2
  ChallengeResponseAuthentication: no
  PasswordAuthentication:          no
  X11Forwarding:                   no
  UsePAM:                          yes
  UseDNS:                          yes
  #
  # Sets the number of client alive messages which may be sent without sshd(8) receiving any messages back from the client.  If this threshold is reached while client alive messages are being sent,
  # sshd will disconnect the client, terminating the session.  It is important to note that the use of client alive messages is very different from TCPKeepAlive.  The client alive messages are sent
  # through the encrypted channel and therefore will not be spoofable.  The TCP keepalive option enabled by TCPKeepAlive is spoofable.  The client alive mechanism is valuable when the client or
  # server depend on knowing when a connection has become unresponsive.
  #
  # The default value is 3.  If ClientAliveInterval is set to 15, and ClientAliveCountMax is left at the default, unresponsive SSH clients will be disconnected after approximately 45 seconds.  Set-
  # ting a zero ClientAliveCountMax disables connection termination.
  #
  ClientAliveCountMax:             3
  #
  # Sets a timeout interval in seconds after which if no data has been received from the client, sshd(8) will send a message through the encrypted channel to request a response from the client.
  # The default is 0, indicating that these messages will not be sent to the client.
  #
  ClientAliveInterval:             30

  Subsystem:
    - sftp    /usr/lib/ssh/sftp-server
  AcceptEnv:
    - LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
    - LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
    - LC_IDENTIFICATION LC_ALL
# This is just an example how to do Match entries
#  Match:
#    'User gitlab':
#      # no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty
#      X11Forwarding:        no
#      AllowTcpForwarding:   no
#      PermitTTY:            no
#      AllowAgentForwarding: no
#      GatewayPorts:         no
