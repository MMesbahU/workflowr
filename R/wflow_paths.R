# wflow_paths
#
# Internal function to obtain relevant paths for workflowr project. The paths
# are relative to the current working directory.
#
# error_git: Should the function fail if it can't find a Git repo.
#
# project: path to the workflowr project
#
# Return a list with following elements:
#
# $root: The root directory of the workflowr project
#
# $analysis: The directory that contains \code{_site.yml} and the R Markdown
# files.
#
# $docs: The directory that contains the HTML files and figures.
#
# $git: The .git directory
wflow_paths <- function(error_git = FALSE, project = ".") {

  o <- list()

  # workflowr root
  project <- normalizePath(project)
  o$root <- try(rprojroot::find_rstudio_root_file(path = project),
                silent = TRUE)
  if (class(o$root) == "try-error")
    stop(wrap(
      "Unable to find RStudio Rproj file at the root of the workflowr project.
      Did you delete it?"),
      call. = FALSE)

  # Analysis directory with _site.yml
  top_level_files <- list.files(path = o$root, full.names = TRUE)
  subdirs <- top_level_files[dir.exists(top_level_files)]
  site_file <- list.files(path = subdirs, pattern = "_site.yml",
                          full.names = TRUE)
  if (length(site_file) == 0) {
    stop(wrap("Unable to find the file _site.yml in the analysis directory.
              Is this a workflowr project?"), call. = FALSE)
  } else if (length(site_file) > 1) {
    stop(wrap("Found more than one _site.yml file. Only one subdirectory at the
              top level of the workflowr project can contain _site.yml."),
         call. = FALSE)
  } else {
    o$analysis <- dirname(site_file)
  }

  # docs/ directory
  output_dir <- yaml::yaml.load_file(site_file)$output_dir
  if (is.null(output_dir))
    stop(wrap("Unable to locate the website directory. Make sure to set the
              variable output_dir in the file _site.yml"),
         call. = FALSE)
  o$docs <- normalizePath(file.path(o$analysis, output_dir), mustWork = FALSE)
  if (!dir.exists(o$docs)) {
    warning("Unable to locate docs directory. Run wflow_build() to create it.")
  }

  # Git repository
  r <- try(git2r::repository(o$root, discover = TRUE), silent = TRUE)
  if (class(r) == "try-error") {
    if (error_git) {
      stop(wrap("A Git repository is required for this functionality."),
           call. = FALSE)
    } else {
      o$git <- NA
    }
  } else {
    o$git <- remove_trailing_slash(r@path)
  }

  # Make paths relative to working directory
  o <- lapply(o, relpath)

  return(o)
}
