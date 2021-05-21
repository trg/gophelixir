defmodule Gophelixir.Server do
  require Logger

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Gophelixir.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> response()
    |> write_line(socket)
    |> :gen_tcp.close()

    serve(socket)
  end

  defp read_line({:error, :closed}) do
    # The connection was closed, exit politely
    exit(:shutdown)
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        :gen_tcp.recv(socket, 0)
        data
      _ -> exit(:shutdown)
    end
  end

  defp write_line(_socket, {:error, :closed}) do
    # The connection was closed, exit politely
    exit(:shutdown)
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
    socket
  end

  def response(_) do
    ~s(0About internet Gopher\tStuff:About us\trawBits.micro.umn.edu\t70\r\n\
1Around University of Minnesota\tZ,5692,AUM\tunderdog.micro.umn.edu\t70\r\n\
1Microcomputer News & Prices\tPrices/\tpserver.bookstore.umn.edu\t70\r\n\
1Courses, Schedules, Calendars\t\tevents.ais.umn.edu\t9120\r\n\
1Student-Staff Directories\t\tuinfo.ais.umn.edu\t70\r\n\
1Departmental Publications\tStuff:DP:\trawBits.micro.umn.edu\t70\r\n\
\r\n\
.\r\n\
)
  end
end
