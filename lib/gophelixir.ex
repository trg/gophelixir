defmodule Gophelixir do
  use Application

  alias Gophelixir.Server


  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")
    children = [
      {Task.Supervisor, name: Gophelixir.TaskSupervisor},
      {Task, fn -> Server.accept(port) end}
    ]

    opts = [strategy: :one_for_one, name: Gophelixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
