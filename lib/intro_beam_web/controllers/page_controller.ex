defmodule IntroBeamWeb.PageController do
  use IntroBeamWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
