# Goal of the script: pre-process and clean file "datos_constituyentes.csv"
library(readr)
library(dplyr)
library(here)
library(janitor, include.only = "clean_names")

datos_constituyentes_raw <-
  read_csv(here("raw_data", "datos_constituyentes.csv"),
           col_types = cols(
             Nombre = col_character(),
             Distrito = col_integer(),
             Lista = col_character(),
             `Agrupacion/movimiento` = col_character(),
             Twitter = col_character(),
             Genero = col_character(),
             Edad = col_character()
           )) %>%
  clean_names()

# Pre-processing
datos_constituyentes <-
  datos_constituyentes_raw %>%
  mutate(
    # convert age into integer
    edad = readr::parse_integer(str_trim(edad)),
    lista_grouped = fct_lump_min(lista, 2, other_level = "Otros"),
    # clean the twitter handle with regexes
    # Logic based on if it's an URL or not
    twitter_handle = case_when(
      str_detect(twitter, "twitter.com") ~
        str_match(twitter, "twitter.com\\/(\\w+).*")[,2],
      str_detect(str_trim(twitter), " ") ~ "",
      TRUE ~ twitter
    ))

write_rds(datos_constituyentes,
          here("data", "datos_constituyentes_clean.rds"))

