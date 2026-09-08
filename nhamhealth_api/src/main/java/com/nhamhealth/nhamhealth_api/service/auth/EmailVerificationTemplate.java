package com.nhamhealth.nhamhealth_api.service.auth;

final class EmailVerificationTemplate {

  private EmailVerificationTemplate() {
  }

  static String subject(String code, boolean isLogin) {
    return isLogin
        ? code + " is your NhamHealth login verification code"
        : code + " is your NhamHealth verification code";
  }

  static String plainText(String code, boolean isLogin) {
    String action = isLogin ? "log in to your NhamHealth account" : "verify your NhamHealth email";
    return """
        NhamHealth Verification

        Your verification code is %s.

        Enter this code in the NhamHealth app to %s. It expires in 5 minutes.

        If you did not request this verification code, you can safely ignore this email. Never share this code with anyone.

        NhamHealth
        Better health, one day at a time.
        """
        .formatted(code, action);
  }

  static String html(String code, boolean isLogin) {
    String title = isLogin ? "Login Verification" : "Verify Your Email";
    String actionText = isLogin ? "log in to your NhamHealth account" : "complete your NhamHealth account registration";
    return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta name="color-scheme" content="light">
          <meta name="supported-color-schemes" content="light">
          <title>NhamHealth Verification</title>
        </head>
        <body style="margin:0;padding:0;background-color:#eff8f2;font-family:Arial,'Helvetica Neue',sans-serif;color:#16452d;">
          <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">
            Use code %s to %s. It expires in 5 minutes.
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
                      <div style="font-size:12px;line-height:16px;font-weight:700;letter-spacing:1px;color:#00a651;text-transform:uppercase;">Account Security</div>
                      <h1 style="margin:8px 0 0;font-size:24px;line-height:30px;color:#075e2d;">%s</h1>
                      <p style="margin:14px 0 0;font-size:15px;line-height:22px;color:#436652;">
                        Enter the verification code below in the app to %s:
                      </p>
                      <div style="margin:24px 0 10px;text-align:center;padding:18px;background-color:#f0f9f3;border:1px dashed #7cc695;border-radius:16px;">
                        <span style="font-size:32px;font-weight:800;letter-spacing:8px;color:#075e2d;font-family:monospace;">%s</span>
                      </div>
                      <p style="margin:16px 0 0;font-size:13px;line-height:18px;color:#6b8a76;text-align:center;">
                        This code expires in <strong>5 minutes</strong>. If you did not request this code, you can safely ignore this email.
                      </p>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:18px 34px;background-color:#f8fbf9;border-top:1px solid #e7f0e9;font-size:12px;line-height:18px;color:#859e8f;text-align:center;">
                      &copy; NhamHealth. All rights reserved.
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
        """
        .formatted(code, actionText, title, actionText, code);
  }
}
