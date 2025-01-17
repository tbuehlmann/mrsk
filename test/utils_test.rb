require "test_helper"

class UtilsTest < ActiveSupport::TestCase
  test "argumentize" do
    assert_equal [ "--label", "foo=\"\\`bar\\`\"", "--label", "baz=\"qux\"", "--label", :quux ], \
      Kamal::Utils.argumentize("--label", { foo: "`bar`", baz: "qux", quux: nil })
  end

  test "argumentize with redacted" do
    assert_kind_of SSHKit::Redaction, \
      Kamal::Utils.argumentize("--label", { foo: "bar" }, sensitive: true).last
  end

  test "argumentize_env_with_secrets" do
    ENV.expects(:fetch).with("FOO").returns("secret")

    args = Kamal::Utils.argumentize_env_with_secrets({ "secret" => [ "FOO" ], "clear" => { BAZ: "qux" } })

    assert_equal [ "-e", "FOO=[REDACTED]", "-e", "BAZ=\"qux\"" ], Kamal::Utils.redacted(args)
    assert_equal [ "-e", "FOO=\"secret\"", "-e", "BAZ=\"qux\"" ], Kamal::Utils.unredacted(args)
  end

  test "optionize" do
    assert_equal [ "--foo", "\"bar\"", "--baz", "\"qux\"", "--quux" ], \
      Kamal::Utils.optionize({ foo: "bar", baz: "qux", quux: true })
  end

  test "optionize with" do
    assert_equal [ "--foo=\"bar\"", "--baz=\"qux\"", "--quux" ], \
      Kamal::Utils.optionize({ foo: "bar", baz: "qux", quux: true }, with: "=")
  end

  test "no redaction from #to_s" do
    assert_equal "secret", Kamal::Utils.sensitive("secret").to_s
  end

  test "redact from #inspect" do
    assert_equal "[REDACTED]".inspect, Kamal::Utils.sensitive("secret").inspect
  end

  test "redact from SSHKit output" do
    assert_kind_of SSHKit::Redaction, Kamal::Utils.sensitive("secret")
  end

  test "redact from YAML output" do
    assert_equal "--- ! '[REDACTED]'\n", YAML.dump(Kamal::Utils.sensitive("secret"))
  end

  test "escape_shell_value" do
    assert_equal "\"foo\"", Kamal::Utils.escape_shell_value("foo")
    assert_equal "\"\\`foo\\`\"", Kamal::Utils.escape_shell_value("`foo`")

    assert_equal "\"${PWD}\"", Kamal::Utils.escape_shell_value("${PWD}")
    assert_equal "\"${cat /etc/hostname}\"", Kamal::Utils.escape_shell_value("${cat /etc/hostname}")
    assert_equal "\"\\${PWD]\"", Kamal::Utils.escape_shell_value("${PWD]")
    assert_equal "\"\\$(PWD)\"", Kamal::Utils.escape_shell_value("$(PWD)")
    assert_equal "\"\\$PWD\"", Kamal::Utils.escape_shell_value("$PWD")

    assert_equal "\"^(https?://)www.example.com/(.*)\\$\"",
      Kamal::Utils.escape_shell_value("^(https?://)www.example.com/(.*)$")
    assert_equal "\"https://example.com/\\$2\"",
      Kamal::Utils.escape_shell_value("https://example.com/$2")
  end

  test "uncommitted changes exist" do
    Kamal::Utils.expects(:`).with("git status --porcelain").returns("M   file\n")
    assert_equal "M   file", Kamal::Utils.uncommitted_changes
  end

  test "uncommitted changes do not exist" do
    Kamal::Utils.expects(:`).with("git status --porcelain").returns("")
    assert_equal "", Kamal::Utils.uncommitted_changes
  end
end
