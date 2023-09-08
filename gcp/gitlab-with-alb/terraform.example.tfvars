project_id = "my-project-id"

tls_cert_path        = "/$REPLACEMEN/.acme.sh/gitlab-private-gcp.sg.dev_ecc/fullchain.cer"
tls_private_key_path = "/$REPLACEME/.acme.sh/gitlab-private-gcp.sg.dev_ecc/gitlab-private-gcp.sg.dev.key"

authorized_consumer_projects = {
  "replace-with-sourcegraph-managed-gcp-project-id" : {
    id : "replace-with-sourcegraph-managed-gcp-project-id",
    limit : 10,
  }
}
