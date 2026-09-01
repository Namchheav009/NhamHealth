package com.nhamhealth.nhamhealth_api.service.auth;

final class PasswordResetEmailTemplate {

    private PasswordResetEmailTemplate() {
    }

    static String subject(String code) {
        return code + " is your NhamHealth password reset code";
    }

    static String plainText(String code) {
        return """
                Reset your NhamHealth password

                Your NhamHealth verification code is %s.

                Enter this code in the NhamHealth app. It expires in 3 minutes.

                If you did not request a password reset, you can safely ignore this email. Never share this code with anyone.

                NhamHealth
                Better health, one day at a time.
                """.formatted(code);
    }

    static String html(String code) {
        return """
                <!doctype html>
                <html lang="en">
                <head>
                  <meta charset="utf-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1">
                  <meta name="color-scheme" content="light">
                  <meta name="supported-color-schemes" content="light">
                  <title>NhamHealth password reset</title>
                </head>
                <body style="margin:0;padding:0;background-color:#eff8f2;font-family:Arial,'Helvetica Neue',sans-serif;color:#16452d;">
                  <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">
                    Use code %s to reset your NhamHealth password. It expires in 3 minutes.
                  </div>
                  <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" border="0" style="width:100%%;background-color:#eff8f2;">
                    <tr>
                      <td align="center" style="padding:32px 14px;">
                        <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" border="0" style="width:100%%;max-width:600px;background-color:#ffffff;border:1px solid #dcebe0;border-radius:24px;overflow:hidden;box-shadow:0 12px 30px rgba(7,94,45,0.10);">
                          <tr>
                            <td style="padding:26px 32px;background-color:#075e2d;">
                              <table role="presentation" cellspacing="0" cellpadding="0" border="0">
                                <tr>
                                  <td width="48" height="48" align="center" valign="middle" style="width:48px;height:48px;border-radius:14px;background-color:#00a651;color:#ffffff;font-size:23px;font-weight:800;">N</td>
                                  <td style="padding-left:14px;color:#ffffff;">
                                    <div style="font-size:22px;line-height:26px;font-weight:800;letter-spacing:-0.3px;">NhamHealth</div>
                                    <div style="padding-top:3px;font-size:12px;line-height:16px;color:#bce6ca;">Better health, one day at a time.</div>
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding:38px 34px 32px;">
                              <div style="font-size:13px;line-height:18px;font-weight:800;letter-spacing:1.2px;text-transform:uppercase;color:#00a651;">Password reset</div>
                              <h1 style="margin:10px 0 12px;font-size:28px;line-height:35px;letter-spacing:-0.6px;color:#075e2d;">Here is your verification code</h1>
                              <p style="margin:0;font-size:15px;line-height:24px;color:#52705e;">Enter this four-digit code in the NhamHealth app to choose a new password.</p>

                              <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" border="0" style="margin:28px 0 18px;width:100%%;background-color:#f1fff2;border:1px solid #bce6ca;border-radius:18px;">
                                <tr>
                                  <td align="center" style="padding:25px 18px 10px;font-size:12px;line-height:16px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:#52705e;">Your reset code</td>
                                </tr>
                                <tr>
                                  <td align="center" style="padding:0 18px 16px;font-family:'Courier New',monospace;font-size:40px;line-height:48px;font-weight:800;letter-spacing:12px;color:#075e2d;">%s</td>
                                </tr>
                                <tr>
                                  <td align="center" style="padding:0 18px 24px;">
                                    <span style="display:inline-block;padding:7px 12px;border-radius:999px;background-color:#dff6e7;color:#075e2d;font-size:12px;line-height:16px;font-weight:700;">&#9201;&nbsp; Expires in 3 minutes</span>
                                  </td>
                                </tr>
                              </table>

                              <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" border="0" style="width:100%%;">
                                <tr>
                                  <td width="34" valign="top" style="padding-top:1px;">
                                    <div style="width:26px;height:26px;border-radius:50%%;background-color:#00a651;color:#ffffff;font-size:13px;line-height:26px;text-align:center;font-weight:800;">1</div>
                                  </td>
                                  <td style="padding:2px 0 14px;font-size:14px;line-height:22px;color:#385744;">Return to the NhamHealth verification screen.</td>
                                </tr>
                                <tr>
                                  <td width="34" valign="top" style="padding-top:1px;">
                                    <div style="width:26px;height:26px;border-radius:50%%;background-color:#00a651;color:#ffffff;font-size:13px;line-height:26px;text-align:center;font-weight:800;">2</div>
                                  </td>
                                  <td style="padding:2px 0 0;font-size:14px;line-height:22px;color:#385744;">Enter the code above and set your new password.</td>
                                </tr>
                              </table>

                              <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" border="0" style="margin-top:28px;width:100%%;background-color:#fff8e8;border-left:4px solid #ff9800;border-radius:10px;">
                                <tr>
                                  <td style="padding:14px 16px;font-size:13px;line-height:20px;color:#705725;"><strong style="color:#5d4619;">Keep your account safe.</strong><br>NhamHealth will never ask you to share this code. If you did not request a reset, you can safely ignore this email.</td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                          <tr>
                            <td align="center" style="padding:20px 28px;background-color:#f8faf5;border-top:1px solid #e4eee6;font-size:12px;line-height:18px;color:#7e9488;">
                              This is an automated security email from NhamHealth.<br>Please do not reply to this message.
                            </td>
                          </tr>
                        </table>
                        <div style="padding:18px 10px 0;font-size:11px;line-height:17px;color:#7e9488;">NhamHealth &bull; Healthy choices made simpler</div>
                      </td>
                    </tr>
                  </table>
                </body>
                </html>
                """.formatted(code, code);
    }
}
