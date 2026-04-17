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
        $configuredPrefix = config('app.public_prefix', '');

        if (is_string($configuredPrefix)) {
            $configuredPrefix = trim($configuredPrefix);

            if ($configuredPrefix !== '' && $configuredPrefix !== '/') {
                return '/'.trim($configuredPrefix, '/');
            }
        }

        if (! app()->bound('request')) {
            return '';
        }

        $request = request();
        $scriptCandidates = array_filter([
            $request->server('ORIGINAL_SCRIPT_FILENAME'),
            $request->server('SCRIPT_FILENAME'),
        ], static fn ($value) => is_string($value) && $value !== '');

        $publicIndex = self::normalizePath(public_path('index.php'));
        $rootEntryPoints = [
            base_path('index.php'),
        ];
        $normalizedRootEntries = array_map(self::normalizePath(...), $rootEntryPoints);

        foreach ($scriptCandidates as $candidate) {
            $normalizedCandidate = self::normalizePath($candidate);

            if ($normalizedCandidate === $publicIndex) {
                return '';
            }

            if (in_array($normalizedCandidate, $normalizedRootEntries, true)) {
                return '/public';
            }
        }

        return '';
    }

    private static function relativePath(string $path): string
    {
        $trimmedPath = ltrim($path, '/');
        $prefix = self::prefix();

        return ($prefix !== '' ? $prefix : '').'/'.$trimmedPath;
    }

    private static function normalizePath(string $path): string
    {
        $resolvedPath = realpath($path);
        $path = $resolvedPath !== false ? $resolvedPath : $path;

        return str_replace('\\', '/', $path);
    }
}
