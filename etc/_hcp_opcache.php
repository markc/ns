<?php
// hcp/opcache.php 20190622 - 20190622
// Copyright (C) 1995-2019 Mark Constable <markc@renta.net> (AGPL-3.0)

echo '<pre>';
var_export(opcache_get_status(false));
//var_export(opcache_get_status(true)); // show scripts
echo "\n\n";
var_export(opcache_get_configuration());
echo '</pre>';
