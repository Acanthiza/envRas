

  # mung ----------
  
  out_names <- c("source"
                 , "collection"
                 , "res"
                 , "period"
                 , "epoch"
                 , "season"
                 , "layer"
                 )

  epoch_seasons <- envFunc::make_epochs(start_year = settings[["start_year", exact = TRUE]]
                                        , end_year = settings[["end_year", exact = TRUE]]
                                        , epoch_step = 10
                                        , epoch_overlap = FALSE
                                        ) %>%
    tidyr::unnest(cols = c(years)) %>%
    dplyr::rename(year = years) %>%
    dplyr::select(year, epoch) %>%
    dplyr::left_join(settings[["seasons", exact = TRUE]]$seasons) %>%
    dplyr::left_join(results) %>%
    dplyr::filter(!is.na(path)) %>%
    tidyr::nest(data = -c(source, collection, aoi, buffer, res, layer, epoch, season)) %>%
    tidyr::unite(col = "out_file", tidyselect::any_of(out_names), sep = "__", remove = FALSE) %>%
    dplyr::mutate(stack = purrr::map(data
                                     , ~ terra::rast(.$path)
                                     )
                  , out_file = fs::path(gsub("30$", "blah", settings[["munged_dir", exact = TRUE]])
                                        , paste0(out_file, ".tif")
                                        )
                  , done = file.exists(out_file)
                  ) %>%
    dplyr::left_join(get_layers)
  
  fs::dir_create(settings[["munged_dir", exact = TRUE]])
  
  purrr::pwalk(list(epoch_seasons$stack[!epoch_seasons$done]
                    , epoch_seasons$out_file[!epoch_seasons$done]
                    , epoch_seasons$func[!epoch_seasons$done]
                    )
               , function(a, b, c) align_func(stack = a
                                              , out_file = b
                                              , func = c
                                              , base = epoch_seasons$stack[[1]][[1]]
                                              , na.rm = TRUE
                                              )
               )
  