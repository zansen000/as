#!/bin/bash
echo "This installer might in rare cases not work with some themes, I am not responsible for the addon working on themes, ask your theme author if it doesn't work."
read -p "Do you want to proceed? (y/n): " answer

if [[ "$answer" == [Yy] ]]; then
    sed "/use Ramsey\\\\Uuid\\\\Uuid;/a use Pterodactyl\\\\Models\\\\Server;" app/Console/Kernel.php > "/tmp/Kernel.php" && mv "/tmp/Kernel.php" app/Console/Kernel.php

    pattern="/\$schedule->command(CleanServiceBackupFilesCommand::class)->daily();/a \\
    \\
        \$schedule->call(function () { \\
            \$servers = Server::where('exp_date', '<', now())->get(); \\
            \$suspensionService = \\\\App::make('Pterodactyl\\\\Services\\\\Servers\\\\SuspensionService'); \\
            foreach (\$servers as \$server) { \\
                if(\$server->status != 'suspended') { \\
                    if(\$server->status != 'installing') { \\
                        if(\$server->exp_date != '0000-00-00') { \\
                            \$suspensionService->toggle(\$server, 'suspend'); \\
                        } \\
                    } \\
                } \\
            } \\
        })->dailyAt('00:05');"

    sed -e "$pattern" app/Console/Kernel.php > "/tmp/Kernel.php" && mv "/tmp/Kernel.php" app/Console/Kernel.php

    sed "/'owner_id', 'external_id', 'name', 'description',/a \\\t\t\t'exp_date'," app/Http/Controllers/Admin/ServersController.php > "/tmp/ServersController.php" && mv "/tmp/ServersController.php" app/Http/Controllers/Admin/ServersController.php

    sed "/'oom_disabled' => 'sometimes|boolean',/a \\
            'exp_date' => \$rules['exp_date']," app/Http/Requests/Api/Application/Servers/StoreServerRequest.php > "/tmp/StoreServerRequest.php" && mv "/tmp/StoreServerRequest.php" app/Http/Requests/Api/Application/Servers/StoreServerRequest.php

    sed "/'oom_disabled' => array_get(\$data, 'oom_disabled'),/a \\
            'exp_date' => array_get(\$data, 'exp_date')," app/Http/Requests/Api/Application/Servers/StoreServerRequest.php > "/tmp/StoreServerRequest.php" && mv "/tmp/StoreServerRequest.php" app/Http/Requests/Api/Application/Servers/StoreServerRequest.php

    sed "/'backup_limit' => 'present|nullable|integer|min:0',/a \\
        'exp_date' => 'sometimes|nullable'," app/Models/Server.php > "/tmp/Server.php" && mv "/tmp/Server.php" app/Models/Server.php

    sed "/'description' => Arr::get(\$data, 'description') ?? '',/a \                'exp_date' => Arr::get(\$data, 'exp_date') ?? null," app/Services/Servers/DetailsModificationService.php > "/tmp/DetailsModificationService.php" && mv "/tmp/DetailsModificationService.php" app/Services/Servers/DetailsModificationService.php

    sed "/'backup_limit' => Arr::get(\$data, 'backup_limit') ?? 0,/a \\
                'exp_date' => Arr::get(\$data, 'exp_date') ?? null," app/Services/Servers/ServerCreationService.php > "/tmp/ServerCreationService.php" && mv "/tmp/ServerCreationService.php" app/Services/Servers/ServerCreationService.php

    sed "/'name' => \$server->name,/a \\
                'exp_date' => \$server->exp_date," app/Transformers/Api/Client/ServerTransformer.php > "/tmp/ServerTransformer.php" && mv "/tmp/ServerTransformer.php" app/Transformers/Api/Client/ServerTransformer.php

    sed "/name: string;/a \\
        expDate: string;" resources/scripts/api/server/getServer.ts > "/tmp/getServer.ts" && mv "/tmp/getServer.ts" resources/scripts/api/server/getServer.ts

    sed "/name: data.name,/a \\
        expDate: data.exp_date," resources/scripts/api/server/getServer.ts > "/tmp/getServer.ts" && mv "/tmp/getServer.ts" resources/scripts/api/server/getServer.ts

    sed "/faMicrochip,/a \\
        faCalendarDay," resources/scripts/components/server/console/ServerDetailsBlock.tsx > "/tmp/ServerDetailsBlock.tsx" && mv "/tmp/ServerDetailsBlock.tsx" resources/scripts/components/server/console/ServerDetailsBlock.tsx

    sed "/const limits = ServerContext.useStoreState((state) => state.server.data!.limits);/a \\
        const expDate = ServerContext.useStoreState((state) => state.server.data!.expDate);" resources/scripts/components/server/console/ServerDetailsBlock.tsx > "/tmp/ServerDetailsBlock.tsx" && mv "/tmp/ServerDetailsBlock.tsx" resources/scripts/components/server/console/ServerDetailsBlock.tsx

    sed -i -e '/<StatBlock icon={faMicrochip} title={'\''CPU Load'\''} color={getBackgroundColor(stats.cpu, limits.cpu)}>/{x;p;x;}' -e '\%<StatBlock icon={faMicrochip} title={'\''CPU Load'\''} color={getBackgroundColor(stats.cpu, limits.cpu)}>%'"{s%^%\t\t\t<StatBlock icon={faCalendarDay} title={\'Expiration Date\'}>\n\t\t\t\t{expDate !== '0000-00-00' ? expDate : '-/-/-'}\n\t\t\t<\/StatBlock>\n%}" resources/scripts/components/server/console/ServerDetailsBlock.tsx

    sed "/<p class=\"text-muted small\">Character limits: <code>a-zA-Z0-9_-<\/code> and <code>\[Space\]<\/code>.<\/p>/,/<\/div>/ {\
    /<\/div>/ {\
    s|<\/div>|&\n                    <div class=\"form-group\">\n                        <label for=\"exp_date\" class=\"control-label\">Expiration date<\/label>\n                        <input type=\"date\" name=\"exp_date\" value=\"{{ old('exp_date', \$server->exp_date) }}\" class=\"form-control\" \\/>\n                        <p class=\"text-muted small\">The expiration date of this server. (Leave blank to keep the server from expiring)<\\/p>\n                    <\\/div>|\
    }\
    }" resources/views/admin/servers/view/details.blade.php > "/tmp/details.blade.php" && mv "/tmp/details.blade.php" resources/views/admin/servers/view/details.blade.php

    sed "/<p class=\"small text-muted no-margin\">Email address of the Server Owner.<\/p>/,/<\/div>/ {
    /<\/div>/ {
    s|<\/div>|&\n\n\t\t\t\t\t\t<div class=\"form-group\">\n\t\t\t\t\t\t\t<label for=\"exp_date\">Expiration date<\/label>\n\t\t\t\t\t\t\t<input type=\"date\" class=\"form-control\" id=\"expiration\" name=\"exp_date\" value=\"{{ old('exp_date') }}\" placeholder=\"Expiration Date\">\n\t\t\t\t\t\t\t<p class=\"small text-muted no-margin\">The expiration date of this server. (Leave blank to keep the server from expiring)<\/p>\n\t\t\t\t\t\t<\/div>|
    }
    }" resources/views/admin/servers/new.blade.php > "/tmp/new.blade.php" && mv "/tmp/new.blade.php" resources/views/admin/servers/new.blade.php


    #ssh comamands
    php artisan view:clear && php artisan cache:clear && php artisan route:clear && php artisan migrate --force && chown -R www-data:www-data *

    yarn
    if [ $? -eq 0 ]; then
        yarn build:production
    else
        if [[ "$(uname -s)" == "Linux" && -f "/etc/centos-release" ]]; then
            curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -

            centos_version=$(grep -oP '(?<=release )[0-9]+' /etc/centos-release)
            if [[ "$centos_version" == "7" ]]; then
                sudo yum install -y nodejs yarn
            elif [[ "$centos_version" == "8" ]]; then
                sudo dnf install -y nodejs yarn
            else
                echo "CentOS version not supported by pterodactyl, please install yarn manually" >&2
            fi
        else
            curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
            apt install -y nodejs
        fi

        npm i -g yarn
        yarn
        yarn build:production
    fi
else
    echo "Abort."
fi
