import sus_woEOwoRAM from '@/assets/conditions/woEO-woRAM/susceptibility.jpg';
import sus_wEOwoRAM  from '@/assets/conditions/wEO-woRAM/susceptibility.jpg';
import sus_woEOwRAM  from '@/assets/conditions/woEO-wRAM/susceptibility.jpg';
import sus_wEOwRAM   from '@/assets/conditions/wEO-wRAM/susceptibility.jpg';

import sev_woEOwoRAM from '@/assets/conditions/woEO-woRAM/severity.jpg';
import sev_wEOwoRAM  from '@/assets/conditions/wEO-woRAM/severity.jpg';
import sev_woEOwRAM  from '@/assets/conditions/woEO-wRAM/severity.jpg';
import sev_wEOwRAM   from '@/assets/conditions/wEO-wRAM/severity.jpg';

import drZ_woEOwoRAM from '@/assets/conditions/woEO-woRAM/dr-zhang.jpg';
import drZ_wEOwoRAM  from '@/assets/conditions/wEO-woRAM/dr-zhang.jpg';
import drZ_woEOwRAM  from '@/assets/conditions/woEO-wRAM/dr-zhang.jpg';
import drZ_wEOwRAM   from '@/assets/conditions/wEO-wRAM/dr-zhang.jpg';

import ic_woEOwoRAM  from '@/assets/conditions/woEO-woRAM/initial-consultation.jpg';
import ic_wEOwoRAM   from '@/assets/conditions/wEO-woRAM/initial-consultation.jpg';
import ic_woEOwRAM   from '@/assets/conditions/woEO-wRAM/initial-consultation.jpg';
import ic_wEOwRAM    from '@/assets/conditions/wEO-wRAM/initial-consultation.jpg';

const ASSETS = {
  'woEO-woRAM': { susceptibility: sus_woEOwoRAM, severity: sev_woEOwoRAM, drZhang: drZ_woEOwoRAM, initialConsultation: ic_woEOwoRAM },
  'wEO-woRAM':  { susceptibility: sus_wEOwoRAM,  severity: sev_wEOwoRAM,  drZhang: drZ_wEOwoRAM,  initialConsultation: ic_wEOwoRAM  },
  'woEO-wRAM':  { susceptibility: sus_woEOwRAM,  severity: sev_woEOwRAM,  drZhang: drZ_woEOwRAM,  initialConsultation: ic_woEOwRAM  },
  'wEO-wRAM':   { susceptibility: sus_wEOwRAM,   severity: sev_wEOwRAM,   drZhang: drZ_wEOwRAM,   initialConsultation: ic_wEOwRAM   },
};

export function getAssets(condition) {
  return ASSETS[condition] || ASSETS['woEO-woRAM'];
}
