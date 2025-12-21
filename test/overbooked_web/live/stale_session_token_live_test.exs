defmodule OverbookedWeb.StaleSessionTokenLiveTest do
  use OverbookedWeb.ConnCase, async: true

  alias Overbooked.Accounts
  import Overbooked.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "stale session tokens" do
    test "redirects to login when session token is invalid", %{conn: conn} do
      user = user_fixture()
      stale_token = Accounts.generate_user_session_token(user)
      Accounts.delete_session_token(stale_token)

      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:user_token, stale_token)
        |> get(Routes.home_path(conn, :index))

      assert redirected_to(conn) == Routes.login_path(conn, :index)
    end

    test "renders login page when session token is invalid", %{conn: conn} do
      user = user_fixture()
      stale_token = Accounts.generate_user_session_token(user)
      Accounts.delete_session_token(stale_token)

      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:user_token, stale_token)
        |> get(Routes.login_path(conn, :index))

      {:ok, _view, html} = live(conn)
      assert html =~ "Log in"
    end
  end
end

