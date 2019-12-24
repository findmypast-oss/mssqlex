defmodule Mssqlex.Stream do
  @moduledoc false
  defstruct [:conn, :query, :params, :options]
  @type t :: %Mssqlex.Stream{}
end

defmodule Mssqlex.Cursor do
  @moduledoc false
  defstruct [:portal, :ref, :connection_id, :mode]
  @type t :: %Mssqlex.Cursor{}
end

defmodule Mssqlex.Copy do
  @moduledoc false
  defstruct [:portal, :ref, :connection_id, :query]
  @type t :: %Mssqlex.Copy{}
end

defimpl Enumerable, for: Mssqlex.Stream do
  alias Mssqlex.Query

  def reduce(%Mssqlex.Stream{query: %Query{} = query} = stream, acc, fun) do
    %Mssqlex.Stream{conn: conn, params: params, options: opts} = stream

    stream = %DBConnection.Stream{
      conn: conn,
      query: query,
      params: params,
      opts: opts
    }

    DBConnection.reduce(stream, acc, fun)
  end

  def reduce(%Mssqlex.Stream{query: statement} = stream, acc, fun) do
    %Mssqlex.Stream{conn: conn, params: params, options: opts} = stream
    query = %Query{name: "", statement: statement}
    opts = Keyword.put(opts, :function, :prepare_open)

    stream = %DBConnection.PrepareStream{
      conn: conn,
      query: query,
      params: params,
      opts: opts
    }

    DBConnection.reduce(stream, acc, fun)
  end

  def member?(_, _) do
    {:error, __MODULE__}
  end

  def count(_) do
    {:error, __MODULE__}
  end

  def slice(_) do
    {:error, __MODULE__}
  end
end

defimpl Collectable, for: Mssqlex.Stream do
  alias Mssqlex.Stream
  alias Mssqlex.Query

  def into(%Stream{conn: %DBConnection{}} = stream) do
    %Stream{conn: conn, query: query, params: params, options: opts} = stream
    opts = Keyword.put(opts, :postgrex_copy, true)

    case query do
      %Query{} ->
        copy = DBConnection.execute!(conn, query, params, opts)
        {:ok, make_into(conn, stream, copy, opts)}

      query ->
        query = %Query{name: "", statement: query}
        {_, copy} = DBConnection.prepare_execute!(conn, query, params, opts)
        {:ok, make_into(conn, stream, copy, opts)}
    end
  end

  def into(_) do
    raise ArgumentError,
          "data can only be copied to database inside a transaction"
  end

  defp make_into(conn, stream, %Mssqlex.Copy{ref: ref} = copy, opts) do
    fn
      :ok, {:cont, data} ->
        _ = DBConnection.execute!(conn, copy, {:copy_data, ref, data}, opts)
        :ok

      :ok, close when close in [:done, :halt] ->
        _ = DBConnection.execute!(conn, copy, {:copy_done, ref}, opts)
        stream
    end
  end
end

defimpl DBConnection.Query, for: Mssqlex.Copy do
  alias Mssqlex.Copy

  def parse(copy, _) do
    raise "can not prepare #{inspect(copy)}"
  end

  def describe(copy, _) do
    raise "can not describe #{inspect(copy)}"
  end

  def encode(%Copy{ref: ref}, {:copy_data, ref, data}, _) do
    try do
      encode_msg(msg_copy_data(data: data))
    rescue
      ArgumentError ->
        reraise ArgumentError,
                "expected iodata to copy to database, got: " <> inspect(data)
    else
      iodata ->
        {:copy_data, iodata}
    end
  end

  def encode(%Copy{ref: ref}, {:copy_done, ref}, _) do
    :copy_done
  end

  def decode(copy, _result, _opts) do
    raise "can not describe #{inspect(copy)}"
  end

  defp encode_msg(_data) do
    throw("encode_msg not implemented")
  end

  defp msg_copy_data(_data) do
    throw("msg_copy_data not implemented")
  end
end

defimpl String.Chars, for: Mssqlex.Copy do
  def to_string(%Mssqlex.Copy{query: query}) do
    String.Chars.to_string(query)
  end
end
