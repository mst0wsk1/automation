<?php
/**
 * SMTP Configuration for WordPress
 *
 * This mu-plugin configures WordPress to send emails via SMTP
 * using environment variables for configuration.
 */

add_action('phpmailer_init', function($phpmailer) {
    $host = getenv('SMTP_HOST');
    if (!$host) {
        return;
    }

    $phpmailer->isSMTP();
    $phpmailer->Host       = $host;
    $phpmailer->SMTPAuth   = true;
    $phpmailer->Username   = getenv('SMTP_USER') ?: '';
    $phpmailer->Password   = getenv('SMTP_PASS') ?: '';
    $phpmailer->Port       = (int)(getenv('SMTP_PORT') ?: 587);

    $secure = strtolower(getenv('SMTP_SECURE') ?: 'tls');
    if (in_array($secure, ['ssl', 'tls'], true)) {
        $phpmailer->SMTPSecure = $secure;
    }

    $from = getenv('MAIL_FROM');
    if ($from) {
        $fromName = getenv('MAIL_FROM_NAME') ?: '';
        $phpmailer->setFrom($from, $fromName);
        $phpmailer->addReplyTo($from, $fromName);
    }
});
