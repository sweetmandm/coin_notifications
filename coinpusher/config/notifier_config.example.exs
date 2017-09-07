# Notifier Config
#
#
# NOTE: notifier_config.exs is Generated by ansible/roles/notifier.
#

use Mix.Config

config :coinpusher,
  zmq_address: "127.0.0.1",
  zmq_port: "28332",
  rpc_user: "<generated user>",
  rpc_pass: "<generated pass>",
  rpc_address: "http://127.0.0.1",
  rpc_port: "18332",
  twilio_token: "<token>",
  twilio_sid: "<sid>",
  twilio_from: "<from>"
