defmodule OverbookedWeb.SignupLive do
  use OverbookedWeb, :live_view

  alias OverbookedWeb.Router.Helpers, as: Routes
  alias Overbooked.Accounts
  alias Overbooked.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, assign(socket, changeset: changeset)}
  end

  def render(assigns) do
    ~H"""
    <.header label="Sign up"></.header>
    <.page>
      <div class="max-w-md mt-6">
        <%= if @current_user do %>
          <div class="bg-yellow-50 border border-yellow-200 rounded-md p-4 mb-6">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-yellow-800">
                  You're already logged in
                </h3>
                <div class="mt-2 text-sm text-yellow-700">
                  <p>
                    You're currently signed in as <strong><%= @current_user.email %></strong>.
                    To accept this invitation and create a new account, please
                    <.link href={Routes.user_session_path(@socket, :delete)} method="delete" class="font-medium text-yellow-700 underline hover:text-yellow-600">
                      log out first
                    </.link>.
                  </p>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <.form
            :let={f}
            for={@changeset}
            phx-change={:validate}
            phx-submit={:save}
            id="signup-form"
            class="flex flex-col space-y-4"
          >
            <div class="">
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div class="mt-1">
                <.text_input form={f} field={:email} phx_debounce="blur" required={true} />
                <.error form={f} field={:email} />
              </div>
            </div>
            <div class="">
              <label for="name" class="block text-sm font-medium text-gray-700">
                Full name
              </label>
              <div class="mt-1">
                <.text_input form={f} field={:name} phx_debounce="blur" required={true} />
                <.error form={f} field={:name} />
              </div>
            </div>
            <div class="">
              <label for="password" class="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div class="mt-1">
                <.password_input
                  form={f}
                  phx_debounce="blur"
                  field={:password}
                  value={input_value(f, :password)}
                  required={true}
                />
                <.error form={f} field={:password} />
              </div>
            </div>
            <div class="">
              <label for="password_confirmation" class="block text-sm font-medium text-gray-700">
                Confirm password
              </label>
              <div class="mt-1">
                <.password_input
                  form={f}
                  phx_debounce="blur"
                  field={:password_confirmation}
                  value={input_value(f, :password_confirmation)}
                  required={true}
                />
                <.error form={f} field={:password_confirmation} />
              </div>
            </div>

            <div class="py-2">
              <.button type="submit" phx-disable-with="Registering...">Register</.button>
            </div>
          </.form>

          <p>
            <.link class="text-sm" navigate={Routes.login_path(@socket, :index)}>Log in</.link>
            |
            <.link class="text-sm" navigate={Routes.user_forgot_password_path(@socket, :index)}>
              Forgot your password?
            </.link>
          </p>
        <% end %>
      </div>
    </.page>
    """
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, token: params["token"])}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Overbooked.Accounts.change_user_registration(user_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user_with_token(socket.assigns.token, user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(socket, :confirm_account, &1)
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Account created successfully. Please check your email for confirmation instructions."
         )
         |> redirect(to: Routes.user_resend_confirmation_path(socket, :index))}

      {:error,
       %Ecto.Changeset{errors: [registration_token: {"Invalid registration token!", []}]} =
           changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Your sign up token is invalid, please ask your admin to resend it"
         )
         |> assign(changeset: changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
