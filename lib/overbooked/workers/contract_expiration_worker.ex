defmodule Overbooked.Workers.ContractExpirationWorker do
  @moduledoc """
  Oban worker that sends contract expiration warning emails.
  Triggered by the NotificationSweeper for contracts expiring in 7 days.
  """
  use Oban.Worker, queue: :notifications, max_attempts: 3

  alias Overbooked.Repo
  alias Overbooked.Contracts.Contract
  alias Overbooked.Accounts.UserNotifier

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"contract_id" => contract_id, "days_remaining" => days_remaining}}) do
    contract =
      Repo.get(Contract, contract_id)
      |> Repo.preload([:resource, :user])

    case contract do
      nil ->
        Logger.warning("ContractExpirationWorker: Contract #{contract_id} not found")
        :ok

      %Contract{expiration_warning_sent_at: sent} when not is_nil(sent) ->
        Logger.info("ContractExpirationWorker: Warning already sent for contract #{contract_id}")
        :ok

      %Contract{status: status} when status != :active ->
        Logger.info("ContractExpirationWorker: Contract #{contract_id} is not active (status: #{status})")
        :ok

      contract ->
        send_warning(contract, days_remaining)
    end
  end

  defp send_warning(contract, days_remaining) do
    case UserNotifier.deliver_contract_expiration_warning(contract.user, contract, days_remaining) do
      {:ok, _email} ->
        # Mark warning as sent
        contract
        |> Ecto.Changeset.change(%{expiration_warning_sent_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update!()

        Logger.info("ContractExpirationWorker: Sent expiration warning for contract #{contract.id}")
        :ok

      {:error, reason} ->
        Logger.error("ContractExpirationWorker: Failed to send warning for contract #{contract.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
