<?php

namespace App\Support;

class PublicAssetUrl
{
    public static function toUrl(string $path): string
    {
        $relativePath = self::relativePath($path);

        if (app()->runningInConsole() && ! app()->bound('request')) {
            return asset(ltrim($relativePath, '/'));
        }

        return $relativePath;
    }

    public static function prefix(): string
    {
        $prefix = config('app.public_prefix', '');

        if (! is_string($prefix)) {
            return '';
        }

        $prefix = trim($prefix);

        if ($prefix === '' || $prefix === '/') {
            return '';
        }

        return '/'.trim($prefix, '/');
    }

    private static function relativePath(string $path): string
    {
        $trimmedPath = ltrim($path, '/');
        $prefix = self::prefix();

        return ($prefix !== '' ? $prefix : '').'/'.$trimmedPath;
    }
}
