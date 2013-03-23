module.exports = function (app,redis_req,database,crypto,DB){
	app.get('/admin/apps/del/:appid', function (req, res) {
    	var appid = req.params.appid.replace(/\W/g, '');
    	database.Applications.find(appid).success(function(app){
        	if (app && appid != 1){
            	app.destroy().success(function () {
            	});
        	}
        	res.redirect('/admin/apps/'+req.session.auth.client);
    	});
	});
	app.get('/admin/apps/details/:appid', function (req, res) {
    	var appid = req.params.appid.replace(/\W/g, '');
    	database.Applications.find(appid).success(function(app){
        	res.render('apps/add', {flux:app,session:req.session.auth});
    	});
		
	});
	
	app.get('/admin/poolers/:client', function (req, res) {
    	var client = req.params.client.replace(/\W/g, '');
       	res.render('apps/poolers', {flux:null,session:req.session.auth});
	});
	
	app.post('/admin/apps/add', function (req, res) {
        var data = req.body.app;
        data.ClientId = req.session.auth.client;
        data.active = parseInt(data.active);
        database.Applications.build(data).saveorupdate(function(model){
            if (model.active == 1){
                DB.sadd("Clients",model.ClientId);
                DB.sadd("Apps",model.ClientId+":"+model.id);
                DB.sadd("AppsKey",model.ClientId+":"+model.id+":"+model.secretkey);
            }else{
                DB.srem("Clients",model.ClientId);
                
                DB.srem("Apps",model.ClientId+":"+model.id);
                DB.srem("Apps:"+model.ClientId,model.id);
                
                DB.srem("AppsKey",model.ClientId+":"+model.id+":"+model.secretkey);
            }
            return res.redirect('/admin/apps/'+req.session.auth.client);
        });
	});
	app.get('/admin/apps/add', function (req, res) {
        res.render('apps/add', {flux:{},session:req.session.auth});
	});
	
	app.get('/admin/apps/:client', function (req, res) {
    	var client = req.params.client.replace(/\W/g, '');
    	
    	database.Applications.findAll({where:{ClientId:req.session.auth.client}}).success(function(apps){
    	   res.render('apps/list', {flux:apps,session:req.session.auth});
    	});
	});
}