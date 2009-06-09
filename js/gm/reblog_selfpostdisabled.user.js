// ==UserScript==
// @name           Reblog Self Post Disabled
// @namespace      http://sugizou.jugem.jp/
// @include        http://www.tumblr.com/*
// @exclude        
// ==/UserScript==

var func = function() {
    base = "/html/body[@id='dashboard_index']/div[@id='container']/div[@id='content']/div[@id='left_column']/ol[@id='posts']/li";
    res = document.evaluate(base, document, null, 7, null);
    
    cnt = 0;
    do {
      field = res.snapshotItem(cnt);
      id    = field.getAttribute('id');
      chk   = field.getAttribute('class');
      
      reg   = new RegExp('is_mine');
      if(id != null && chk.match(reg)) {
	path = base + "[@id='" + id + "']";
	docs = document.evaluate(path, document, null, 7, null);
	target = docs.snapshotItem(0).innerHTML = '<span style="color: text;">Your Post.</span>';
      }
      cnt++;
    } while(res.snapshotItem(cnt) != null);
}

func();

if (typeof AutoPagerize != 'undefined') {
  AutoPagerize.addFilter(func);
}
// 
