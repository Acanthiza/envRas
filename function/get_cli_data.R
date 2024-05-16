  
  get_cli_data <- function(urls_df
                           , out_file
                           , func
                           , base
                           , scale
                           , offset
                           ) {
    
    r <- purrr::map(urls_df$file
                    , safe_nc
                    , proxy = TRUE
                    ) %>%
      purrr::map("result") %>%
      purrr::discard(is.null)
    
    if(length(r)) {
    
      r %>%
        purrr::map(sf::st_set_crs, settings$epsg_latlong) %>%
        purrr::map(`[`
                   , i = settings$boundary %>%
                     sf::st_transform(crs = settings$epsg_latlong)
                   ) %>%
        purrr::map(stars::st_as_stars
                   , proxy = FALSE
                   ) %>%
        do.call("c", .) %>%
        aggregate(by = "3 months"
                  , FUN = get(func)
                  , na.rm = TRUE
                  ) %>%
        terra::rast() %>% # switch to terra as stars::write_stars seemed to have trouble with Inf values
        terra::project(y = terra::crs(base)) %>%
        terra::writeRaster(filename = out_file
                           , names = gsub("\\.tif", "", basename(out_file))
                           , datatype = "INT2S"
                           , scale = scale
                           , offset = offset
                           , gdal = c("COMPRESS = NONE")
                           )
      
    }
    
    return(invisible(NULL))
    
  }
  