{:ok, _} = Application.ensure_all_started(:ex_machina)

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    {:shared, tags: tags}
  end

  config.finally fn(_shared) ->
    :ok
  end
end
