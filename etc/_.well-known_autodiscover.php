<?php
// .well-know/autodiscover.php 20190430 - 20190711
// Copyright (C) 1995-2019 Mark Constable <markc@renta.net> (AGPL-3.0)

$pfqdn = str_replace(['autoconfig.', 'autodiscover.'], '', $_SERVER['HTTP_HOST']);
$mhost = dns_get_record($pfqdn, DNS_MX)[0]['target'];

$configXML = explode('?', $_SERVER['REQUEST_URI']);
$configXML = $configXML[0];

switch(strtolower($configXML)) {
    case '/autodiscover':
    case '/autodiscover/':
    case '/autodiscover/autodiscover.xml': {
        $data = file_get_contents('php://input');
        preg_match("/\<EMailAddress\>(.*?)\<\/EMailAddress\>/", $data, $matches);
        $output = autodiscover(@$matches[1], $mhost, $pfqdn);
        break;
    }
    case '/mail/config-v1.1.xml':
    case '/.well-known/autoconfig/mail/config-v1.1.xml': {
        $output = autoconfig(@$_GET['emailaddress'], $mhost, $pfqdn);
        break;
    }
    default: {
        header("HTTP/1.0 404 Not Found");
        exit;
        break;
  }
}

header("Content-type: text/xml; charset=utf-8");
print $output;
exit;

function autodiscover($email, $mhost, $pfqdn)
{
    return <<<XML
<?xml version="1.0" encoding="utf-8"?>
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
  <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    <Account>
      <AccountType>email</AccountType>
      <Action>settings</Action>
      <Protocol>
        <Type>IMAP</Type>
        <Server>$mhost</Server>
        <Port>993</Port>
        <DomainRequired>on</DomainRequired>
        <SPA>off</SPA>
        <SSL>on</SSL>
        <AuthRequired>on</AuthRequired>
        <LoginName>$email</LoginName>
      </Protocol>
      <Protocol>
        <Type>SMTP</Type>
        <Server>$mhost</Server>
        <Port>465</Port>
        <DomainRequired>on</DomainRequired>
        <SPA>off</SPA>
        <SSL>on</SSL>
        <AuthRequired>on</AuthRequired>
        <UsePOPAuth>on</UsePOPAuth>
        <SMTPLast>off</SMTPLast>
        <LoginName>$email</LoginName>
      </Protocol>
    </Account>
  </Response>
</Autodiscover>
XML;
}

function autoconfig($emailaddress = null, $mhost, $pfqdn)
{
    return <<<XML
<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1">
  <emailProvider id="$pfqdn">
    <domain>$pfqdn</domain>
    <displayName>$pfqdn</displayName>
    <displayShortName>$pfqdn</displayShortName>
    <incomingServer type="imap">
      <hostname>$mhost</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <outgoingServer type="smtp">
      <hostname>$mhost</hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
    <documentation url="https://support.google.com/mail/troubleshooter/1668960?rd=1">
      <descr lang="en">Getting started with IMAP and POP3</descr>
    </documentation>
  </emailProvider>
</clientConfig>
XML;
}
