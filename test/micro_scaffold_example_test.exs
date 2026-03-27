defmodule MicroScaffoldExampleTest do
  use ExUnit.Case
  doctest MicroScaffoldExample

  test "greets the world" do
    assert MicroScaffoldExample.hello() == :world
  end
end
