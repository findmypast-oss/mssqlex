defmodule Mssqlex.Mixfile do
  use Mix.Project

  def project do
    [app: :mssqlex,
     version: "0.8.0",
     description: "Adapter to Microsoft SQL Server. Using DBConnection and ODBC.",
     elixir: ">= 1.4.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     aliases: aliases(),

     # Testing
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["test.local": :test,
                         "coveralls": :test,
                         "coveralls.travis": :test],

     # Docs
     name: "Mssqlex",
     source_url: "https://github.com/findmypast-oss/mssqlex",
     docs: [main: "readme",
            extras: ["README.md"]]]
  end

  def application do
    [extra_applications: [:logger, :odbc]]
  end

  defp deps do
    [{:db_connection, "~> 1.1"},
     {:decimal, "~> 1.0"},
     {:ex_doc, "~> 0.15", only: :dev, runtime: false},
     {:excoveralls, "~> 0.6", only: :test},
     {:inch_ex, "~> 0.5", only: :docs},
     {:exfmt, "~> 0.4.0", only: :dev}]
  end

  defp package do
    [name: :mssqlex,
     files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Steven Blowers", "Jae Bach Hardie"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/findmypast-oss/mssqlex"}]
  end

  defp aliases do
    ["test.local": [&setup_env/1, "test"]]
  end

  defp setup_env(_) do
    System.put_env("MSSQL_UID", "sa")
    System.put_env("MSSQL_PWD", "ThePa$$word")
  end
end
