defmodule Backoffice.ResourceView do
  use Phoenix.HTML

  use Phoenix.View,
    root: "lib/backoffice/templates",
    namespace: Backoffice

  import Phoenix.LiveView.Helpers

  def form_field(form, field, opts) do
    type = Map.fetch!(opts, :type)
    opts = Map.delete(opts, :type)

    do_form_field(form, field, type, Enum.into(opts, []))
  end

  defp maybe_disabled(opts) do
    case Keyword.get(opts, :disabled) do
      true -> "bg-gray-200"
      _ -> ""
    end
  end

  defp do_form_field(form, field, :integer, opts) do
    opts =
      Keyword.merge(
        [
          class:
            "#{maybe_disabled(opts)} mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md transition"
        ],
        opts
      )

    number_input(form, field, opts)
  end

  defp do_form_field(form, field, :textarea, opts) do
    opts =
      Keyword.merge(
        [
          class:
            "#{maybe_disabled(opts)} mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md transition"
        ],
        opts
      )

    textarea(form, field, opts)
  end

  defp do_form_field(form, field, {:parameterized, Ecto.Enum, %{values: values}}, opts) do
    options = values |> Enum.map(&Phoenix.Naming.humanize/1) |> Enum.zip(values)

    opts =
      Keyword.merge(
        [
          class:
            "#{maybe_disabled(opts)} mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
        ],
        opts
      )

    select(form, field, options, opts)
  end

  defp do_form_field(form, field, {:embed, %{related: schema}}, opts) do
    opts =
      Keyword.merge(
        [
          class:
            "#{maybe_disabled(opts)} mt-2 mb-4 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md transition"
        ],
        opts
      )

    inputs_for(form, field, fn fp ->
      fields =
        for {k, v} <- schema.__changeset__() do
          {k, %{type: v}}
        end

      [
        {:safe, "<div class=\"p-2\">"},
        Enum.map(fields, fn {field, %{type: type}} ->
          [
            label(fp, field, class: "block text-sm font-medium leading-5 text-gray-700"),
            do_form_field(fp, field, type, opts)
          ]
        end),
        {:safe, "</div>"}
      ]
    end)
  end

  defp do_form_field(form, field, {:assoc, %{related: schema}}, opts) do
    opts =
      Keyword.merge(
        [
          disabled: true,
          class:
            "bg-gray-200 mt-2 mb-4 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md transition"
        ],
        opts
      )

    inputs_for(form, field, fn fp ->
      fields = schema.__schema__(:fields)
      types = Enum.map(fields, &schema.__schema__(:type, &1))

      fields =
        for {k, v} <- Enum.zip(fields, types), not is_tuple(v) do
          {k, %{type: v}}
        end

      [
        {:safe, "<div class=\"p-2\">"},
        Enum.map(fields, fn {field, %{type: type}} ->
          [
            label(fp, field, class: "block text-sm font-medium leading-5 text-gray-700"),
            do_form_field(fp, field, type, opts)
          ]
        end),
        {:safe, "</div>"}
      ]
    end)
  end

  # BUG: updating map field doesn't work now
  defp do_form_field(form, field, :map, opts) do
    opts =
      Keyword.merge(
        [
          class:
            "#{maybe_disabled(opts)} mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md transition",
          value: inspect(input_value(form, field))
        ],
        opts
      )

    textarea(form, field, opts)
  end

  defp do_form_field(form, field, :boolean, opts) do
    opts =
      Keyword.merge(
        opts,
        class:
          "focus:ring-indigo-500 h-4 w-4 mt-2 mb-4 text-indigo-600 border-gray-300 rounded transition"
      )

    checkbox(form, field, opts)
  end

  # TODO: Would be nice to support LiveComponent for more complex component
  #   For example, I would like to have a drop-down suggestion logic as I type.
  defp do_form_field(form, field, :component, opts) do
    component = Keyword.fetch!(opts, :render)
    opts = Keyword.merge(opts, value: input_value(form, field))

    live_component(_, component, opts)
  end

  # Q: Are there any pitfall to allowing user render fields like this?
  defp do_form_field(form, field, :custom, opts) do
    render = Keyword.fetch!(opts, :render)

    render.(form, field)
  end

  defp do_form_field(form, field, _type, opts) do
    opts =
      Keyword.merge(
        [
          class:
            "#{maybe_disabled(opts)} mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md transition"
        ],
        opts
      )

    text_input(form, field, opts)
  end

  def get_class(%{class: class}), do: class

  def get_class(_) do
    "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
  end

  def sort_indicator(params, field) when is_atom(field) do
    sort_indicator(params, to_string(field))
  end

  def sort_indicator(%{"order_by" => <<"[desc]", field::binary>>}, field) do
    {:safe,
     """
     <svg class="mt-1 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4h13M3 8h9m-9 4h9m5-4v12m0 0l-4-4m4 4l4-4" />
     </svg>
     """}
  end

  def sort_indicator(%{"order_by" => <<"[asc]", field::binary>>}, field) do
    {:safe,
     """
     <svg class="mt-1 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4h13M3 8h9m-9 4h6m4 0l4-4m0 0l4 4m-4-4v12" />
     </svg>
     """}
  end

  def sort_indicator(_, _), do: ""

  def column_name({_field, %{label: label}}), do: label
  def column_name({field, _}), do: Phoenix.Naming.humanize(field)

  def column_value(resource, {_field, %{value: value}}) when is_function(value) do
    {:safe, value.(resource) || ""}
  end

  def column_value(resource, {field, %{type: :boolean}}) do
    {:safe,
     """
     <div class="flex items-center h-5">
        <input disabled #{Map.get(resource, field) && "checked"} type="checkbox" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded">
      </div>
     """}
  end

  def column_value(resource, {field, %{type: :map}}) do
    Map.get(resource, field) |> Jason.encode!(pretty: true)
  end

  def column_value(resource, {field, _}) do
    Map.get(resource, field)
  end

  def action_name(action, opts) when is_map(opts) do
    case opts[:label] do
      nil -> Phoenix.Naming.humanize(action)
      label -> label
    end
  end

  def maybe_confirm(%{confirm: false}), do: ""
  def maybe_confirm(%{confirm: msg}), do: {:safe, ["data-confirm=", "\"", msg, "\""]}

  def live_modal(_socket, component, opts) do
    return_to = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: return_to, component: component, opts: opts]
    live_component(socket, Backoffice.ModalComponent, modal_opts)
  end

  def page_nav(socket, %{page: page}, params, route) do
    previous_params = Map.put(params, :page, page.page_number - 1)
    next_params = Map.put(params, :page, page.page_number + 1)

    ~e"""
      <nav class="bg-white px-4 py-3 flex items-center justify-between border-b border-gray-200 sm:px-6">
      <div>
        <p class="text-sm leading-5 text-gray-700">
          Showing
          <span class="font-medium">
            <%= (page.page_number * page.page_size - page.page_size) + 1 %>
          </span>
          to
          <span class="font-medium">
            <%= min(page.total_entries, (page.page_number * page.page_size)) %>
          </span>
          of
          <span class="font-medium">
            <%= page.total_entries %>
          </span>
          results
        </p>
      </div>
      <div class="ml-3 flex-1 flex justify-end">
        <%= if page.page_number > 1 do %>
          <%= live_patch "Previous", to: route.(socket, :index, previous_params), class: "ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 active:bg-gray-100 active:text-gray-700 transition ease-in-out duration-150" %>
        <% end %>
        <%= unless page.page_number == page.total_pages do %>
          <%= live_patch "Next", to: route.(socket, :index, next_params), class: "ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 active:bg-gray-100 active:text-gray-700 transition ease-in-out duration-150" %>
        <% end %>
      </div>
    </nav>
    """
  end
end
