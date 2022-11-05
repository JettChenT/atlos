import Config

# Configure your database
config :platform, Platform.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "platform_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  types: Platform.Repo.PostgresTypes

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :platform, PlatformWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "+Kar+D2VzqX69d3OGBUmSmonaBmr8HWvIDpthNfCsWPqSJzzmRZyum54SoEqv8MI",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    npx: [
      "tailwindcss",
      "--input=css/app.css",
      "--output=../priv/static/assets/app.css",
      "--postcss",
      "--watch",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :platform, PlatformWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(assets|images)/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/platform_web/(live|views)/.*(ex)$",
      ~r"lib/platform_web/templates/.*(eex)$"
    ]
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

if File.exists?("config/dev.secret.exs") do
  import_config("dev.secret.exs")
end

config :appsignal, :config, active: false

System.put_env("INSTANCE_NAME", "Development")
System.put_env("COMMUNITY_DISCORD_LINK", "https://discord.gg/gqCcHc9Gav")

System.put_env(
  "ATTRIBUTE_OPTIONS",
  """
  {
    "type": [
      "Civilian Harm"
    ],
    "impact": [
      "Residential",
      "Industrial",
      "Administrative",
      "Healthcare",
      "School or childcare",
      "Military",
      "Undefined",
      "Commercial",
      "Religious",
      "Cultural",
      "Roads/Highways/Transport",
      "Humanitarian",
      "Food/Food Infrastructure"
    ],
    "equipment": [
      "Unknown",
      "HE rocket artillery",
      "HE tube artillery",
      "HE artillery inc mortars",
      "Cluster munitions",
      "Incendiary munitions",
      "Cruise missile",
      "Ballistic missile",
      "Thermobaric munition",
      "Vehicle mounted weapon",
      "Small arms",
      "Air strike",
      "Land mines",
      "Anti-air missile",
      "Loitering munition"
    ]
  }
  """
)

System.put_env("AUTOTAG_USER_INCIDENTS", "[\"Volunteer\", \"User Created\"]")
System.put_env("DEVELOPMENT_MODE", "true")
