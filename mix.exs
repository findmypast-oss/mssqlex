defmodule Mssqlex.Mixfile do
  use Mix.Project

  def project do
    [app: :mssqlex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases(),
     preferred_cli_env: ["test.local": :test],

     # Docs
     name: "Mssqlex",
     source_url: "https://github.com/findmypast/mssqlex",
     docs: [main: "Mssqlex",
            extras: ["README.md"]]]
  end

  def application do
    [extra_applications: [:logger, :odbc],
     mod: {Mssqlex.Application, []}]
  end

  defp deps do
    [{:db_connection, "~> 1.1"},
     {:ex_doc, "~> 0.15", only: :dev, runtime: false}]
  end

  defp aliases do
    ["test.local": [&setup_env/1, "test"]]
  end

  defp setup_env(_) do
    System.put_env("MSSQL_UID", "sa")
    System.put_env("MSSQL_PWD", "ThePa$$word")
  end
end
