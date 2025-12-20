defmodule Overbooked.Accounts.UserNotifier do
  import Swoosh.Email

  alias Overbooked.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    {from_name, from_email} = get_from_address()

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp get_from_address do
    # Try to get from database settings first
    case get_mail_config() do
      %{from_name: name, from_email: email} when not is_nil(email) ->
        {name, email}

      _ ->
        # Fall back to application config or defaults
        config = Application.get_env(:overbooked, :mail_defaults, [])
        name = Keyword.get(config, :from_name, "Hatchbridge Rooms")
        email = Keyword.get(config, :from_email, "noreply@example.com")
        {name, email}
    end
  end

  defp get_mail_config do
    if Process.whereis(Overbooked.Repo) do
      try do
        Overbooked.Settings.get_mailgun_config()
      rescue
        _ -> nil
      end
    else
      nil
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_user_invitation_instructions(email, url) do
    deliver(email, "Confirmation instructions", """

    ==============================

    Hi #{email},

    You can register your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
