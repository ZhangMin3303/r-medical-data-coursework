# No installs, private machine paths or package downloads.
cat("R:", as.character(getRversion()), "\n")
if (!requireNamespace("survival", quietly = TRUE)) stop("Missing survival package.")
cat("survival:", as.character(utils::packageVersion("survival")), "\n")
cat("PNG capability:", capabilities("png"), "\n")
cat("Validated reference: R 4.4.1 and survival 3.6.4; other versions are not yet verified.\n")
if (getRversion() != "4.4.1" || utils::packageVersion("survival") != "3.6.4") {
  warning("Your versions differ from the validated reference; rerun tests before interpreting output.")
}
