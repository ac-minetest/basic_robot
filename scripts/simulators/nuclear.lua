-- rnd 2017
if not data then
	data = {FUEL = 1.8,TV=0,T=0,P=0,E=0;}

	generate_nuclear_power = function(CONTROL,COOLING)
		if COOLING>1 then COOLING = 1 elseif COOLING<0 then COOLING = 0 end
		if CONTROL>1 then CONTROL = 1 elseif CONTROL<0 then CONTROL = 0 end
		--data = ...
		local FUEL = data.FUEL;
		local TV = data.TV;
		local T = data.T;
		local P = data.P;
		local E = data.E;
		
		-- reactor specifications
		local TVmax = 10000;
		local FUELC = 2; -- critical mass for fuel
		local DECAYRATE = 1-0.01; -- how much fuel decays per time step
		local COOLINGCOEF = 1; -- how efficient is cooling per 1 unit of power (how many degrees are cooled)
		local PCOEF = 1; -- how efficiently temperature is converted to power
	
		local TGV = FUEL/(1-(FUEL/FUELC)^2);
		if TGV>TVmax then TGV = TVmax end; if FUEL>FUELC then TGV = TVmax end  -- basic temperature generation speed generated in core
		TV = TV + TGV* CONTROL - P*COOLING*COOLINGCOEF; -- temperature change speed
		T = T + TV ;
		P = 0.5*P + T*PCOEF; P = P - P*COOLING -- produced power
		FUEL = FUEL*DECAYRATE;
		if P<0 then P = 0 end if T<0 then T = 0 end E=E+P;
		
		data.FUEL = FUEL;
		data.T = T;
		data.TV = TV;
		data.P = P;
		data.E = E
		return E, P, T, FUEL, TV
	end
	
	render = function(data) -- data should be normalized [0,1]
		local tname = "pix.png";
		local obj = _G.basic_robot.data[self.name()].obj;
		local n  = 150; local m = n;
		local length = #data; if length == 0 then return end
		local hsize = 1; local wsize=hsize;
		local tex = "[combine:"..(wsize*m).."x"..(hsize*n);
		for i = 1,length do
			j=math.floor((1-data[i])*m);
			local ix = math.floor((i/length)*n)
			tex = tex .. ":"..(ix*wsize).."," .. (j*hsize) .. "="..tname
		end
		obj:set_properties({visual = "sprite",textures = {tex}})
	end
	
	tdata = {};
	COOLING = 0.03
	
end

-- generate_nuclear_power(CONTROL, COOLING)
-- CONTROL = 0.20; -- control rods; 1 = no control, between 0 and  1
-- COOLING = 0.03; -- how much power assigned for cooling, in ratio of output power P; between 0 and 1


E,P,T,FUEL,TV = generate_nuclear_power(0.2,COOLING)
-- cooling strategy
if TV < 0 then COOLING = 0.0 elseif T>90 then COOLING  = 0.03 else COOLING = 0 end

tdata[#tdata+1]=math.min(T/100,1);
render(tdata)

self.label( "T " .. T .. "\nTV " .. TV .. "\nP ".. P .. "\nFUEL " .. FUEL .. "\nTOTAL ENERGY PRODUCED " .. E )