cd /var/www/pterodactyl || exit 1

for f in resources/scripts/components/server/files/FileNameModal.tsx resources/scripts/components/server/files/FileObjectRow.tsx resources/scripts/components/server/files/NewDirectoryButton.tsx resources/scripts/components/server/files/RenameFileModal.tsx; do

sed -i "/import { join } from 'pathe';/d" "$f"

grep -q "const join = (...paths" "$f" || sed -i "1i const join = (...paths: string[]) => paths.filter(Boolean).join('/');" "$f"

done

sed -i "/@ts-expect-error todo: check on this/d" resources/scripts/components/elements/CopyOnClick.tsx

sed -i "s/import axios, { AxiosProgressEvent } from 'axios';/import axios from 'axios';/g" resources/scripts/components/server/files/UploadButton.tsx

sed -i "s/AxiosProgressEvent/ProgressEvent/g" resources/scripts/components/server/files/UploadButton.tsx

set +H

sed -i "/Assert::isInstanceOf/c\\\$server = \\\$request->route()?->parameter('server');\\n\\nif (is_string(\\\$server) || !(\\\$server instanceof Server)) {\\n    return Limit::none();\\n}" app/Enum/ResourceLimit.php

set -H

blueprint -rerun-install
