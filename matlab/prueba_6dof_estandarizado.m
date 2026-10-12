function prueba_6dof_estandarizado
% Aceptacion de la comparacion fisica y las formulaciones completas.
assert(exist('comparar_f16_estandarizado','file')==2, ...
    'prueba_6dof:Missing','Falta el comparador estandarizado.');
r=comparar_f16_estandarizado;
assert(r.verificacion.max_identidad_no_lineal<1e-7);
assert(r.verificacion.max_newton_euler<1e-8);
assert(r.verificacion.covarianza_A_quat<1e-6);
assert(r.verificacion.covarianza_A_cuerpo<1e-6);
assert(r.verificacion.covarianza_B_quat<1e-6);
assert(r.verificacion.covarianza_B_cuerpo<1e-6);
assert(r.verificacion.integracion_quat_euler<1e-6);
assert(r.verificacion.integracion_cuerpo_euler<1e-6);
assert(r.verificacion.error_actuadores<1e-7);
assert(r.verificacion.max_rotacion<1e-12);
assert(isequal(size(r.matrices.A15),[15 15]));
assert(isequal(size(r.matrices.A14),[14 14]));
assert(isequal(size(r.matrices.A18),[18 18]));
assert(isequal(size(r.matrices.C9),[3 9]));
assert(isequal(size(r.matrices.D9),[3 4]));
assert(r.propio_trim.valido && ~r.punto_lewis_en_modelo_local.valido);
assert(~r.viraje_lewis_en_modelo_local.valido);
assert(strcmp(r.pull_up.estado,'NO_EVALUADO_MANDO_FUERA_DE_DOMINIO'));
assert(real(r.polos_espiral)>0);
assert(r.altitud_frontera.no_diferenciable);
assert(r.verificacion.max_deriva_norma_quat<1e-10);
fprintf('PRUEBA_6DOF_ESTANDARIZADO: PASS\n');
end
