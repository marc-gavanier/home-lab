{
  gsub(/[?&][Aa]ccess_?[Tt]oken=|[?&][Aa]pi_?[Kk]ey=|[?&](token|auth|secret|password|sig|signature)=/, "&\001")
  gsub(/\001[^ &"]*/, "***")

  gsub(/\/api\/push\/[^ ?"]+/, "/api/push/***")

  print
  fflush()
}
